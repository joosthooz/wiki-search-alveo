
#include "software.hpp"
#include <snappy.h>
#include <lz4.h>
#include <omp.h>
#include <chrono>
#include <string.h>
#include <ctype.h>

//#define DEBUG
#ifdef DEBUG
#include <stdio.h>
#undef DEBUG
#define DEBUG(...) fprintf(stderr, __VA_ARGS__)
#else
#define DEBUG(...)
#endif

/**
 * Constructs the software word matcher.
 */
SoftwareWordMatch::SoftwareWordMatch() {
}

/**
 * Resets the dataset stored in device memory.
 */
void SoftwareWordMatch::clear_chunks() {
    chunks.clear();
}

/**
 * Adds the given chunk to the dataset stored in device memory.
 */
void SoftwareWordMatch::add_chunk(const std::shared_ptr<arrow::RecordBatch> &batch) {
    chunks.push_back(batch);
}

/**
 * Runs the kernel with the given configuration.
 */
void SoftwareWordMatch::execute(const WordMatchConfig &config,
    void (*progress)(void *user, const char *status), void *progress_user
) {

    // Get a Table representation of the data.
    std::shared_ptr<arrow::Table> table;
    arrow::Result<std::shared_ptr<arrow::Table>> result = arrow::Table::FromRecordBatches(chunks);
    if (result.ok()) {
	table = result.ValueOrDie();
    } else {
        throw std::runtime_error("Table::FromRecordBatches failed: " + result.status().ToString());
    }

    // Make sure we have enough presults result records and clear them.
    results.cpp_partial_results.resize(omp_get_max_threads());
    for (auto &presults : results.cpp_partial_results) {
        presults.num_word_matches = 0;
        presults.num_page_matches = 0;
        presults.cpp_page_match_counts.clear();
        presults.cpp_page_match_title_offsets.clear();
        presults.cpp_page_match_title_values.clear();
        presults.cpp_page_match_title_offsets.push_back(0);
        presults.max_word_matches = 0;
        presults.cpp_max_page_title.clear();
        presults.cycle_count = 0;
        presults.clock_frequency = 0;
        presults.data_size = 0;
        presults.data_size_uncompressed = 0;
        presults.time_taken = 0;
    }

    // Start measuring execution time.
    auto start = std::chrono::high_resolution_clock::now();
    if (progress) {
        std::string msg = "Running on CPU...";
        progress(progress_user, msg.c_str());
    }

    #pragma omp parallel
    {
        // Determine what our slice of the table and result record is.
        int tcnt = omp_get_num_threads();
        int tid = omp_get_thread_num();
        auto &presults = results.cpp_partial_results[tid];
        int64_t stai = (table->num_rows() * tid) / tcnt;
        int64_t stoi = (table->num_rows() * (tid + 1)) / tcnt;
        auto slice = table->Slice(stai, stoi - stai);
        auto title_chunks = slice->column(0);
        auto data_chunks = slice->column(1);

        // Data buffer for the uncompressed article text.
        std::string article_text;

        // Iterate over the chunks in our slice of the table.
        if (title_chunks->num_chunks() != data_chunks->num_chunks()) {
            throw std::runtime_error("unexpected chunking");
        }
        for (int ci = 0; ci < title_chunks->num_chunks(); ci++) {
            auto titles = std::dynamic_pointer_cast<arrow::StringArray, arrow::Array>(title_chunks->chunk(ci));
            auto data = std::dynamic_pointer_cast<arrow::BinaryArray, arrow::Array>(data_chunks->chunk(ci));
            if (titles->length() != data->length()) {
                throw std::runtime_error("unexpected chunking");
            }
            unsigned int max_page_cnt = 0;
            unsigned int max_page_idx = 0;
            for (unsigned int ii = 0; ii < titles->length(); ii++) {

                // Get the article data pointer and size from Arrow.
                int32_t article_data_size;
                const char *article_data_ptr = (const char*)data->GetValue(ii, &article_data_size);
                presults.data_size += article_data_size + 4;

                // Perform decompression.
                size_t uncompressed_length;
		const char snappy_header[] = {(char)0xff, 0x06, 0x00, 0x00, 0x73, 0x4e, 0x61, 0x50, 0x70, 0x59};
		const char lz4_header[] = {0x04, 0x22, 0x4d, 0x18};
/*		
		for (int i = 0; i < 16; i++) {
		printf("0x%02x ", (unsigned char)article_data_ptr[i]);
		}
		printf("\n");
*/

		if (!strncmp(article_data_ptr, snappy_header, 10)) {
			DEBUG("Snappy\n");
		unsigned int chunk_type = (unsigned char)article_data_ptr[10];
		switch (chunk_type) {
			default:
				printf("Unknown Snappy chunk type (0x%x)\n", chunk_type);
				throw std::runtime_error("snappy decompression error");
				break;
			case 1:
				uncompressed_length = ((unsigned char)article_data_ptr[11] | ((unsigned char)article_data_ptr[12] << 8) | ((unsigned char)article_data_ptr[13] << 16)) - 4; //minus the 4 checksum bytes
				DEBUG("uncompressed chunk (length %lu)\n", uncompressed_length);
				if (uncompressed_length > (article_data_size - 18)) {
					printf("not enough input data available (%lu) for uncompressed chunk size (%lu)\n", 
						article_data_size - 18, uncompressed_length);
					throw std::runtime_error("snappy decompression error");
				}	
				memcpy(&article_text[0], &article_data_ptr[18], uncompressed_length);
				break;
			case 0: //compressed chunk
				DEBUG("compressed chunk\n");
		if (!snappy::GetUncompressedLength(&article_data_ptr[18], article_data_size, &uncompressed_length)) {
		    printf("Snappy library cannot find uncompressed length\n");
                    throw std::runtime_error("snappy decompression error");
                }
		article_text.resize(uncompressed_length);
		if (!snappy::IsValidCompressedBuffer(&article_data_ptr[18], article_data_size-18)) {
		    printf("not valid Snappy\n");
		    break;
		}

                if (!snappy::RawUncompress(&article_data_ptr[18], article_data_size-18, &article_text[0])) {
                //if (!snappy::Uncompress(article_data_ptr, article_data_size, &article_text)) {
		    printf("Error decompressing Snappy\n");
                    //throw std::runtime_error("snappy decompression error");
                }
		}
		
		
		} else if (!strncmp(article_data_ptr, lz4_header, 4)) {
			DEBUG("LZ4\n");

  int offset = 4;
  uint8_t flg = article_data_ptr[offset++];
  uint8_t bd = article_data_ptr[offset++];
  uint8_t max_block_size = ((bd >> 4) & 0x7);

  if (max_block_size != 4) {
    DEBUG("Warning: max block size = %d\n", max_block_size);
  }

  uint8_t version_number = ((flg >> 6) & 0x3);
  DEBUG("version_number=%d\n", version_number);
  uint8_t block_independence = ((flg >> 5) & 0x1);
  DEBUG("block_independence=%d\n", block_independence);
  uint8_t block_checksum_present = ((flg >> 4) & 0x1);
  DEBUG("block_checksum_present=%d\n", block_checksum_present);
  uint8_t content_size_present = ((flg >> 3) & 0x1);
  DEBUG("content_size_present=%d\n", content_size_present);
  uint8_t content_checksum_present = ((flg >> 2) & 0x1);
  DEBUG("content_checksum_present=%d\n", content_checksum_present);
  if (version_number != 0x01) {
    printf("Wrong LZ4 version.\n");
    break; //version must be set to 01
  }
  if (content_size_present) {
	long frame_size = 0;
	for (int i = 0; i < 8; i++) {
		frame_size |= (unsigned char)article_data_ptr[offset + i] << (i * 8);
	}
	DEBUG("frame_size %ull\n", frame_size);
	offset += 8;
  }

  offset++; //frame header checksum

	//uncompressed length is not known for our LZ4 options
	size_t compressed_length = 0;
	for (int i = 0; i < 4; i++) {
                compressed_length |= (unsigned char)article_data_ptr[offset + i] << (i * 8);
	}
	offset += 4;

	if ((compressed_length >> 31) & 1) {
		compressed_length &= ~(1 << 31);
		DEBUG("uncompressed block, size %lu\n", compressed_length);
		if (compressed_length > (article_data_size - offset)) {
                    printf("not enough input data available (%lu) for uncompressed chunk size (%lu)\n",
                        article_data_size - offset, uncompressed_length);
                    throw std::runtime_error("snappy decompression error");
                }
		article_text.resize(compressed_length);
                memcpy(&article_text[0], &article_data_ptr[offset], compressed_length);

	} else {
		DEBUG("compressed_length: %d\n", uncompressed_length);
		article_text.resize(64 * 1024); //64k should be sufficient

		int ret = LZ4_decompress_safe (&article_data_ptr[offset], &article_text[0], compressed_length, 64 * 1024);
		if (ret < 0) {
			printf("LZ4 error %d decompressing data\n", ret);
                        //throw std::runtime_error("LZ4 decompression error");
                }
		}
		} else {
			printf("Error; unknown compression header\n");
		}

                // Perform matching.
                unsigned int num_matches = 0;
                const char *ptr = article_text.c_str();
                const char *end = ptr + strlen(ptr);
                if (config.whole_words) {
                    int patsize = config.pattern.size();
                    bool first = true;
                    ptr--;
                    for (; ptr < end - patsize; ptr++, first = false) {
                        if (strncmp(ptr+1, config.pattern.c_str(), patsize)) {
                            continue;
                        }
                        if (!first && (isalnum(*ptr) || *ptr == '_')) {
                            continue;
                        }
                        if (ptr+1+patsize < end && (isalnum(*(ptr+1+patsize)) || *(ptr+1+patsize) == '_')) {
                            continue;
                        }
                        num_matches++;
                    }
                } else {
                    while (ptr < end) {
                        ptr = strstr(ptr, config.pattern.c_str());
                        if (ptr) {
                            ptr++;
                            num_matches++;
                        } else {
                            break;
                        }
                    }
                }
                presults.data_size_uncompressed += uncompressed_length + 4;

                presults.num_word_matches += num_matches;
                if (num_matches >= config.min_matches) {
                    presults.num_page_matches++;
                    if (presults.cpp_page_match_counts.size() < 256) {
                        presults.cpp_page_match_counts.push_back(num_matches);
                        presults.cpp_page_match_title_values += titles->GetString(ii);
                        presults.cpp_page_match_title_offsets.push_back(
                            presults.cpp_page_match_title_values.size());
                    }
                }
                if (num_matches >= max_page_cnt) {
                    max_page_cnt = num_matches;
                    max_page_idx = ii;
                }
            }

            // Load the title of the page with the most matches.
            if (max_page_cnt >= presults.max_word_matches) {
                presults.max_word_matches = max_page_cnt;
                presults.cpp_max_page_title = titles->GetString(max_page_idx);
            }
        }
    }

    // Finish measuring execution time.
    auto elapsed = std::chrono::high_resolution_clock::now() - start;
    results.time_taken = std::chrono::duration_cast<std::chrono::microseconds>(elapsed).count();
    if (progress) {
        std::string msg = "Running on CPU... done";
        progress(progress_user, msg.c_str());
    }

    // Synchronize all the results.
    for (auto &presults : results.cpp_partial_results) {
        presults.synchronize();
    }
    results.synchronize();

}

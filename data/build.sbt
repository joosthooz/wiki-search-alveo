name := "Wikipedia to Arrow with LZ4/Snappy"

version := "1.0"

scalaVersion := "2.11.12"

val sparkVersion = "2.4.4"
val sparkXmlVersion = "0.6.0"
val snappyVersion = "1.1.7.3"
val lz4Version = "1.7.1"
val arrowVersion = "0.15.0"

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % sparkVersion,
  "org.apache.spark" %% "spark-sql" % sparkVersion,
  "com.databricks"   %% "spark-xml"  % sparkXmlVersion,
  "org.xerial.snappy" % "snappy-java" % snappyVersion,
  "org.lz4" % "lz4-java" % lz4Version,
  "org.apache.arrow" % "arrow-vector" % arrowVersion classifier "shade-format-flatbuffers"
)

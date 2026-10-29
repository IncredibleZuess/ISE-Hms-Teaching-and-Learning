import { S3Client } from "@aws-sdk/client-s3";

const minioClient = new S3Client({
  endpoint: process.env.MINIO_ENDPOINT || "http://minio:9000",
  region: "us-east-1", // required by AWS SDK; value ignored by MinIO
  forcePathStyle: true,
  credentials: {
    accessKeyId: process.env.MINIO_ACCESS_KEY || "minioadmin",
    secretAccessKey: process.env.MINIO_SECRET_KEY || "minioadmin",
  },
});

export default minioClient;

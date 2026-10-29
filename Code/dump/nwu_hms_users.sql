-- MySQL dump 10.13  Distrib 8.0.38, for Win64 (x86_64)
--
-- Host: localhost    Database: nwu_hms
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `userID` int NOT NULL AUTO_INCREMENT,
  `username` char(8) NOT NULL,
  `firstName` varchar(45) NOT NULL,
  `lastName` varchar(45) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phoneNum` varchar(10) NOT NULL,
  `userType` enum('Student','Lecturer','Admin') NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `refreshToken` varchar(255) DEFAULT NULL,
  `resetCode` varchar(6) DEFAULT NULL,
  `codeExpiry` bigint DEFAULT NULL,
  `profilePicture` text,
  PRIMARY KEY (`userID`),
  UNIQUE KEY `username_UNIQUE` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'43151906','Renier','Van Rooyen','$2a$10$06a9AY4X/PsjS3iKw5UjOe..ifUEwCXZaJv01TwKO6ZVEKTTR6woW','43151906@mynwu.ac.za','','Admin','2025-01-01 00:00:00','2025-01-01 00:00:00',NULL,NULL,NULL,NULL),(2,'40887340','Johan','Coetzee','$2a$10$zzdhmWFfXZtc8v9J/LViz.ShXnjMfvfX9dpaIWLYInERBUtNmSJwm','40887340@mynwu.ac.za','','Admin','2025-01-01 00:00:00','2025-01-01 00:00:00',NULL,NULL,NULL,NULL),(3,'42468000','FC','Venter','$2a$10$ZWGrL3yI9Li2cjBi1MfbCuq7aoBr8FkOCDDcfRwQlldz4TCbqjd0m','42468000@mynwu.ac.za','','Admin','2025-01-01 00:00:00','2025-01-01 00:00:00',NULL,NULL,NULL,NULL),(4,'42320755','Rikus','Swart','$2a$10$Y/Mwdo15baQQjIfm8pCuDOEeO68i7dWjmCgPrEylbtYizvasVwYx6','42320755@mynwu.ac.za','','Admin','2025-01-01 00:00:00','2025-01-01 00:00:00',NULL,NULL,NULL,NULL),(5,'28999142','John','Klerck','$2a$10$llsfa5BNx1jJ7O3m9Jxtwu2Gk0HvPNeJWMlXZSSe4iGv6I6em2f4G','john.klerck@nwuenterprises.co.za','','Admin','2025-01-01 00:00:00','2025-01-01 00:00:00',NULL,NULL,NULL,NULL),(6,'12860379','Annerie','Kruger','$2a$10$w.9z9UZv.MGyqRvGuZxI1.O3awsVem9XL0Pn9DINFqVk9IG8plvS.','annerie.kruger@nwu.ac.za','','Admin','2025-01-01 00:00:00','2025-01-01 00:00:00',NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-10-16 22:00:39

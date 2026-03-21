-- MySQL dump 10.13  Distrib 8.0.45, for Linux (x86_64)
--
-- Host: localhost    Database: devopsdb
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `deployments`
--

DROP TABLE IF EXISTS `deployments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deployments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `service_name` varchar(150) NOT NULL,
  `version` varchar(50) NOT NULL,
  `environment` enum('dev','staging','production') NOT NULL,
  `status` enum('pending','running','success','failed') DEFAULT 'pending',
  `deployed_by` varchar(100) DEFAULT NULL,
  `deployed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_deployments_env` (`environment`),
  KEY `idx_deployments_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deployments`
--

LOCK TABLES `deployments` WRITE;
/*!40000 ALTER TABLE `deployments` DISABLE KEYS */;
INSERT INTO `deployments` VALUES (1,'web-tier','sha-6de8819a','production','success','github-actions','2026-03-18 17:01:16'),(2,'app-tier','sha-6de8819a','production','success','github-actions','2026-03-18 17:01:16'),(3,'web-tier','sha-af44efb9','production','success','github-actions','2026-03-18 17:13:06'),(4,'app-tier','sha-af44efb9','production','success','github-actions','2026-03-18 17:13:06'),(5,'web-tier','sha-6f0c6d9b','production','success','github-actions','2026-03-18 17:23:24'),(6,'app-tier','sha-6f0c6d9b','production','success','github-actions','2026-03-18 17:23:24'),(7,'web-tier','sha-ade85f4e','production','success','github-actions','2026-03-18 17:49:45'),(8,'app-tier','sha-ade85f4e','production','success','github-actions','2026-03-18 17:49:45'),(9,'web-tier','sha-c06f9855','production','success','github-actions','2026-03-18 18:03:33'),(10,'app-tier','sha-c06f9855','production','success','github-actions','2026-03-18 18:03:33'),(11,'web-tier','sha-dacc8415','production','success','github-actions','2026-03-21 21:29:43'),(12,'app-tier','sha-dacc8415','production','success','github-actions','2026-03-21 21:29:43'),(13,'web-tier','sha-7440b589','production','success','github-actions','2026-03-21 21:31:13'),(14,'app-tier','sha-7440b589','production','success','github-actions','2026-03-21 21:31:13'),(15,'web-tier','sha-bdabe756','production','success','github-actions','2026-03-21 21:32:12'),(16,'app-tier','sha-bdabe756','production','success','github-actions','2026-03-21 21:32:12'),(17,'web-tier','sha-311440d7','production','success','github-actions','2026-03-21 22:18:54'),(18,'app-tier','sha-311440d7','production','success','github-actions','2026-03-21 22:18:54'),(19,'web-tier','sha-a505064e','production','success','github-actions','2026-03-21 22:28:08'),(20,'app-tier','sha-a505064e','production','success','github-actions','2026-03-21 22:28:08');
/*!40000 ALTER TABLE `deployments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `login_logs`
--

DROP TABLE IF EXISTS `login_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `login_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `ip_address` varchar(45) NOT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `status` enum('success','failed','locked') DEFAULT 'failed',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_loginlogs_user` (`user_id`),
  KEY `idx_loginlogs_ip` (`ip_address`),
  CONSTRAINT `fk_loginlogs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `login_logs`
--

LOCK TABLES `login_logs` WRITE;
/*!40000 ALTER TABLE `login_logs` DISABLE KEYS */;
INSERT INTO `login_logs` VALUES (1,2,'10.244.0.12','curl/8.5.0','success','2026-03-18 11:32:39'),(2,3,'10.244.0.13','curl/8.5.0','success','2026-03-18 11:40:23'),(3,4,'10.244.0.13','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-18 11:55:07'),(4,5,'10.244.0.15','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-18 12:18:39'),(5,5,'10.244.0.15','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-18 12:19:16'),(6,5,'10.244.0.15','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-18 12:26:30'),(7,6,'10.244.0.15','Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/146.0.7680.40 Mobile/15E148 Safari/604.1','success','2026-03-18 13:02:26'),(8,6,'10.244.0.15','Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/146.0.7680.40 Mobile/15E148 Safari/604.1','success','2026-03-18 13:03:06'),(9,5,'10.244.0.15','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-18 13:19:12'),(10,1,'10.244.0.15','curl/8.5.0','failed','2026-03-18 15:22:57'),(11,1,'10.244.0.15','curl/8.5.0','locked','2026-03-18 15:28:46'),(12,1,'10.244.0.15','curl/8.5.0','locked','2026-03-18 15:28:53'),(13,1,'10.244.0.15','curl/8.5.0','locked','2026-03-18 15:29:16'),(14,1,'10.244.0.15','curl/8.5.0','failed','2026-03-18 15:30:15'),(15,1,'10.244.0.15','curl/8.5.0','failed','2026-03-18 15:30:27'),(16,1,'10.244.0.15','curl/8.5.0','failed','2026-03-18 15:34:59'),(17,1,'10.244.0.15','curl/8.5.0','success','2026-03-18 15:37:44'),(18,1,'10.244.0.18','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-18 15:48:28'),(19,1,'10.244.0.18','curl/8.5.0','success','2026-03-18 15:48:54'),(20,NULL,'10.244.0.18','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','failed','2026-03-18 15:49:22'),(21,5,'10.244.0.18','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','failed','2026-03-18 15:49:53'),(22,5,'10.244.0.18','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','failed','2026-03-18 15:49:59'),(23,5,'10.244.0.18','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-18 15:50:14'),(24,7,'10.244.0.25','curl/8.5.0','success','2026-03-18 17:42:00'),(25,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 18:07:14'),(26,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 18:42:46'),(27,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 18:54:46'),(28,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 18:55:36'),(29,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 18:56:44'),(30,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','failed','2026-03-18 18:57:41'),(31,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','failed','2026-03-18 18:58:06'),(32,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','failed','2026-03-18 18:58:10'),(33,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','failed','2026-03-18 18:58:15'),(34,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','locked','2026-03-18 18:58:20'),(35,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','locked','2026-03-18 18:58:20'),(36,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','locked','2026-03-18 18:58:26'),(37,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','locked','2026-03-18 18:58:29'),(38,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','locked','2026-03-18 18:58:52'),(39,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 19:05:55'),(40,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 19:07:47'),(41,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','locked','2026-03-18 19:08:40'),(42,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 19:10:43'),(43,8,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 19:21:37'),(44,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 19:24:43'),(45,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','failed','2026-03-18 19:28:20'),(46,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 19:28:30'),(47,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 19:30:44'),(48,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36','success','2026-03-18 19:53:12'),(49,1,'10.244.0.32','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-18 20:05:57'),(50,8,'10.244.0.32','Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/146.0.7680.40 Mobile/15E148 Safari/604.1','success','2026-03-18 20:19:46'),(51,1,'10.244.0.37','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-19 13:13:22'),(52,1,'10.244.0.37','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-19 13:54:12'),(53,1,'10.244.0.37','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-19 14:38:23'),(54,1,'10.244.0.44','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 12:25:49'),(55,1,'10.244.0.44','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 14:12:29'),(56,1,'10.244.0.59','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 20:25:11'),(57,1,'10.244.0.59','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 20:36:10'),(58,1,'10.244.0.59','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 20:45:57'),(59,1,'10.244.0.59','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 20:55:43'),(60,1,'10.244.0.59','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 20:57:27'),(61,1,'10.244.0.59','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 21:15:39'),(62,5,'10.244.0.59','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 21:17:24'),(63,1,'10.244.0.59','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 21:17:58'),(64,1,'10.244.0.65','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 21:36:12'),(65,1,'10.244.0.65','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 21:37:12'),(66,1,'10.244.0.65','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 21:43:10'),(67,NULL,'10.244.0.65','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','failed','2026-03-21 21:50:09'),(68,8,'10.244.0.65','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 21:50:27'),(69,1,'10.244.0.65','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 21:50:55'),(70,1,'10.244.0.68','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 22:21:44'),(71,1,'10.244.0.70','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 22:31:31'),(72,1,'10.244.0.70','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 22:32:55'),(73,1,'10.244.0.70','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 22:33:15'),(74,1,'10.244.0.70','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 22:33:26'),(75,9,'10.244.0.70','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 22:35:31'),(76,9,'10.244.0.70','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 22:36:00'),(77,1,'10.244.0.70','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 Edg/146.0.0.0','success','2026-03-21 22:37:27');
/*!40000 ALTER TABLE `login_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `messages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `company` varchar(150) DEFAULT NULL,
  `cloud` enum('AWS','Google Cloud','Azure','Multi-Cloud','On-Premise / Hybrid','') DEFAULT '',
  `message` text NOT NULL,
  `status` enum('new','read','replied') DEFAULT 'new',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_messages_user` (`user_id`),
  KEY `idx_messages_email` (`email`),
  KEY `idx_messages_status` (`status`),
  KEY `idx_messages_created` (`created_at`),
  CONSTRAINT `fk_messages_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
INSERT INTO `messages` VALUES (1,NULL,'Vikrant','Kumar','vikrant@test.com','VickYCloud','AWS','Test message from app','new','2026-03-21 20:01:37'),(2,NULL,'Vikrant','Kumar','vikrant@test.com','VickYCloud','AWS','Testing fixed form','new','2026-03-21 20:24:42'),(3,NULL,'Vikrant','Ore','vikrant@vicky.cloud','VickYCloud','AWS','Testing from fixed form','new','2026-03-21 20:44:04'),(4,NULL,'Sangeeta','Ore','s@gmail.com','delloitte','Google Cloud','hii','new','2026-03-21 20:54:21'),(5,NULL,'Sangeeta','Ore','s@gmail.com','delloitte','Multi-Cloud','Hii From Sangeeta Sandeep Ore','new','2026-03-21 20:55:24'),(6,NULL,'Sandeep','Ore','sandeep@gmail.com','Capgemine','On-Premise / Hybrid','Hii From STO','new','2026-03-21 20:57:21'),(7,NULL,'Piyush','Ore','piyushore.13@gmail.com','Google','Google Cloud','Hii From Piyush Sandeep Ore!!!','new','2026-03-21 22:32:46'),(8,NULL,'Tejram','Ore','Dada@gmail.com','Ore Company','AWS','Miss You Dada!!!','new','2026-03-21 22:37:21');
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reset_tokens`
--

DROP TABLE IF EXISTS `reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reset_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token` varchar(10) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_reset_user` (`user_id`),
  CONSTRAINT `fk_reset_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reset_tokens`
--

LOCK TABLES `reset_tokens` WRITE;
/*!40000 ALTER TABLE `reset_tokens` DISABLE KEYS */;
INSERT INTO `reset_tokens` VALUES (2,5,'592854','2026-03-21 21:31:06',1,'2026-03-21 21:16:06'),(6,8,'512097','2026-03-21 22:04:24',1,'2026-03-21 21:49:24'),(8,1,'377272','2026-03-21 22:40:03',0,'2026-03-21 22:25:03'),(9,5,'602911','2026-03-21 22:46:16',0,'2026-03-21 22:31:16'),(10,8,'189014','2026-03-21 22:46:23',0,'2026-03-21 22:31:23'),(11,6,'981542','2026-03-21 22:48:34',0,'2026-03-21 22:33:34');
/*!40000 ALTER TABLE `reset_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(80) DEFAULT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `company` varchar(150) DEFAULT NULL,
  `role` enum('admin','developer','viewer') DEFAULT 'developer',
  `mfa_enabled` tinyint(1) DEFAULT '0',
  `mfa_secret` varchar(64) DEFAULT NULL,
  `remember_token` varchar(64) DEFAULT NULL,
  `login_attempts` tinyint DEFAULT '0',
  `locked_until` datetime DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `username` (`username`),
  KEY `idx_users_email` (`email`),
  KEY `idx_users_username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'vickyadmin','Vicky','Admin','admin@vicky.cloud','$2y$12$RU0e.HlL8AaqVnEU388oSu0TpWrFFD56sDbhm31zsXAz5dKDiq2Aq',NULL,'admin',0,NULL,NULL,0,NULL,'2026-03-21 22:37:27','2026-03-18 10:31:45','2026-03-21 22:37:27'),(2,'vikrant','Vikrant','Kumar','vikrant@vicky.cloud','$2y$12$a7L/YSHd0mHUVCTQfN9u9esO3A77s30qZcJ3fovlCMP6Z4ADzaMCa','VickYCloud','developer',0,NULL,NULL,0,NULL,NULL,'2026-03-18 11:32:39','2026-03-18 11:32:39'),(3,'vikrant2','Vikrant','Kumar','vikrant2@vicky.cloud','$2y$12$vqwNqXhUz89o3x0kejrXbuVuIk/gE9wAQSe8RVEEJxi2UJn3bLfNG','VickYCloud','developer',0,NULL,NULL,0,NULL,NULL,'2026-03-18 11:40:23','2026-03-18 11:40:23'),(4,'testuser4','Test','User','test4@vicky.cloud','$2y$12$kq2/QQtvWMLg.Mz/RxcIYO631almbpOg2lRdES0nOPB9rEX75Pn2e','VickYCloud','developer',0,NULL,NULL,0,NULL,NULL,'2026-03-18 11:55:07','2026-03-18 11:55:07'),(5,'VIckYCloud','Vikrant','Ore','vikrantore.17@gmail.com','$2y$12$rZu8BF2IiZfvSJ.fAOZieeLbe0IlZ7qBcd/DAnKdkxNU0bNmupncG','fct','developer',0,NULL,NULL,0,NULL,'2026-03-21 21:17:24','2026-03-18 12:18:39','2026-03-21 21:17:24'),(6,'PiyushSheth','Piyush','Ore','piyu@gmail.com','$2y$12$xH5KsAQc6x0GPufMNYAPRencd.oMtKRdxGNoiITTmUyczpuNYrjjK','Ore & Sons','developer',0,NULL,NULL,0,NULL,'2026-03-18 13:03:06','2026-03-18 13:02:26','2026-03-18 13:03:06'),(7,'testuser10','Test','User','test10@vicky.cloud','$2y$12$6KT29E2u5.r85ktWT1v4z.jF4thL7jY86J.6H/QWLe4AtgtW0.Dwu','VickYCloud','developer',0,NULL,NULL,0,NULL,NULL,'2026-03-18 17:42:00','2026-03-18 17:42:00'),(8,'piyushore','piyush','ore','piyushore.13@gmail.com','$2y$12$DyN82hjDuqxx6hgR4qoa3u36sT14EW0YrHy4y6VtVkiBfUpGdoxGG','fct','developer',0,NULL,NULL,0,NULL,'2026-03-21 21:50:27','2026-03-18 18:54:46','2026-03-21 21:50:27'),(9,'Dada','Tejram','Ore','Dada@gmail.com','$2y$12$XwLCc56vnd5l908qJBvTUOmkwdpr7dxpzqGa2FauLNofkos76mQnC','Ore Company','developer',0,NULL,NULL,0,NULL,'2026-03-21 22:36:00','2026-03-21 22:35:31','2026-03-21 22:36:00');
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

-- Dump completed on 2026-03-21 22:39:40

# Spring PetClinic

Spring PetClinic is a sample Spring Boot application that demonstrates the use of Spring technologies in a real-world application.

## Prerequisites

Ensure you have the following installed on your system:
- Java 17 or later
- Maven
- PostgreSQL or MySQL (optional, for database configuration)
- Docker & Docker Compose (optional, for running services in containers)

```bash
sudo apt update && sudo apt install openjdk-17-jdk -y
sudo apt update && sudo apt install maven -y
sudo apt update && sudo apt -y install docker.io
sudo apt install postgresql-client-common
sudo apt-get install postgresql-client
sudo apt install docker-compose
```

## Build and Run the Application localy

### 1. Build the Application

Run the following command to clean and package the application while skipping tests:

```sh
mvn clean package -DskipTests
```

### 2. Run the Application

By default, the application runs using an in-memory database (H2). To start the application:

```sh
java -jar target/spring-petclinic-3.4.0-SNAPSHOT.jar
```

The application will be available at: [http://localhost:8080](http://localhost:8080)

You can then access the Petclinic at <http://localhost:8080/>.

<img width="1042" alt="petclinic-screenshot" src="https://cloud.githubusercontent.com/assets/838318/19727082/2aee6d6c-9b8e-11e6-81fe-e889a5ddfded.png">

Or you can run it from Maven directly using the Spring Boot Maven plugin. If you do this, it will pick up changes that you make in the project immediately (changes to Java source files require a compile as well - most people use an IDE for this):

```bash
./mvnw spring-boot:run
```

## Database setup using docker
You can start MySQL or PostgreSQL locally with whatever installer works for your OS or use docker:

```bash
docker run -e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic -p 3306:3306 mysql:9.1
```

or

```bash
docker run -e POSTGRES_USER=petclinic -e POSTGRES_PASSWORD=petclinic -e POSTGRES_DB=petclinic -p 5432:5432 postgres:17.0
```

## Database configuration
In its default configuration, Petclinic uses an in-memory database (H2) which gets populated at startup with data. The h2 console is exposed at http://localhost:8080/h2-console, and it is possible to inspect the content of the database using the jdbc:h2:mem:<uuid> URL. The UUID is printed at startup to the console.

A similar setup is possible for MySQL and PostgreSQL if a persistent database configuration is needed.

## Configuring External Databases

The application supports PostgreSQL and MySQL. To use a specific database, modify the `application.properties` file or set the active profile accordingly.

### 1. Using PostgreSQL

Modify `src/main/resources/application.properties` to use:

```sh
spring.profiles.active=postgres
```

Or run with:

```sh
java -jar -Dspring.profiles.active=postgres target/spring-petclinic-3.4.0-SNAPSHOT.jar
```

Ensure PostgreSQL is running, and update the database credentials in `application-postgres.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost/petclinic
spring.datasource.username=your_username
spring.datasource.password=your_password
```

### 2. Using MySQL

Modify `src/main/resources/application.properties` to use:

```sh
spring.profiles.active=mysql
```

Or run with:

```sh
java -jar -Dspring.profiles.active=mysql target/spring-petclinic-3.4.0-SNAPSHOT.jar
```

Ensure MySQL is running, and update the database credentials in `application-mysql.properties`:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/petclinic
spring.datasource.username=your_username
spring.datasource.password=your_password
```

## Running with Docker Compose
To run the application using Docker Compose, use the following command:

```sh
docker-compose up --build
```

This setup includes:
- A PostgreSQL database container
- The Spring Boot application container

### Environment Variables
The `docker-compose.yml` file sets up necessary environment variables:

- `SPRING_PROFILES_ACTIVE=postgres` (to activate the PostgreSQL profile)
- `POSTGRES_URL=jdbc:postgresql://petclinic-db:5432/petclinic` (database connection URL)
- `POSTGRES_USER=petclinic`
- `POSTGRES_PASS=petclinic`

You can modify these values in the `docker-compose.yml` file to match your database setup.

## Accessing the Application
Once the application starts, access it at:

```
http://localhost:8080
```

## Stopping the Application
To stop the containers, run:

```sh
docker-compose down
```

## Building a Container

TYou can build a container image (if you have a docker daemon) using the Spring Boot build plugin without Dockerfile aswell:

```bash
./mvnw spring-boot:build-image
```



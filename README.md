# Salary Manager - Backend

A Rails API for managing employee salary information.

## Requirements

- Ruby 3.3.0 or higher
- Rails 7.2.0 or higher
- PostgreSQL 12 or higher
- Node.js 18 or higher (for asset compilation)

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd salary-manager/backend
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Setup Configuration

Copy the example credentials file (if needed):
```bash
cp config/credentials.yml.enc.example config/credentials.yml.enc
```

Or edit credentials using:
```bash
rails credentials:edit
```

### 4. Database Setup

Create the database and run migrations:

```bash
rails db:create
rails db:migrate
```

### 5. Seed the Database (Optional)

To populate the database with sample data:

```bash
rails db:seed
```

## Running the Server

Start the Rails development server:

```bash
rails server
# or
rails s
```

The API will be available at `http://localhost:3000`

## Running Tests

Run the test suite using RSpec:

```bash
bundle exec rspec
```

For specific test file:
```bash
bundle exec rspec spec/models/employee_spec.rb
```

## Code Quality

### Linting with RuboCop

```bash
bundle exec rubocop
```

### Security Analysis with Brakeman

```bash
bundle exec brakeman
```

## Docker

Build and run the application in Docker:

```bash
docker build -t salary-manager-backend .
docker run -p 3000:3000 salary-manager-backend
```

## Environment Variables

Configure environment variables in `.env` or use Rails credentials:

- `RAILS_ENV` - Application environment (development, test, production)
- `DATABASE_URL` - Database connection string (for production)

## API Endpoints

- `GET /employees` - List all employees
- `GET /employees/:id` - Get employee details
- `POST /employees` - Create a new employee
- `PUT /employees/:id` - Update employee
- `DELETE /employees/:id` - Delete employee

## Troubleshooting

### Database Migration Issues

If you encounter migration errors:

```bash
# Reset the database
rails db:drop db:create db:migrate

# Rollback the last migration
rails db:rollback
```

### Bundle Issues

If gems fail to install:

```bash
bundle clean
bundle install
```

## Deployment

For production deployment:

1. Set `RAILS_ENV=production`
2. Configure database and credentials
3. Run `rails db:migrate` on the production server
4. Use a production web server (Puma, etc.)

## Contributing

1. Create a feature branch
2. Commit changes
3. Push to the branch
4. Create a pull request

## License

This project is licensed under the MIT License.

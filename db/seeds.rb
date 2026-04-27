require 'faker'

first_names = File.readlines('lib/data/first_names.txt', chomp: true)
last_names  = File.readlines('lib/data/last_names.txt', chomp: true)

# Clear existing data
Employee.delete_all
User.delete_all

# Create demo user
User.find_or_create_by(email: 'hr@company.com') do |user|
  user.password = 'password123'
  user.name = 'HR Manager'
  user.role = 'admin'
end

puts "✓ Demo user created: hr@company.com / password123"

employees = 10_000.times.map.with_index do |_, index|
  first = first_names.sample
  last  = last_names.sample
  {
    first_name: first,
    last_name: last,
    full_name: "#{first} #{last}",
    emp_id: "EMP#{(index + 1).to_s.rjust(6, '0')}",
    country: Faker::Address.country,
    job_title: Faker::Job.title,
    salary: rand(30_000..200_000),
    department: Faker::Commerce.department
  }
end

Employee.insert_all(employees)
puts "✓ Created 10,000 employees"

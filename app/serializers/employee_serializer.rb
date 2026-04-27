class EmployeeSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :first_name, :last_name, :job_title, :country, :salary, :department, :year_started, :created_at, :updated_at

  attribute :full_name do |employee|
    employee.full_name
  end
end
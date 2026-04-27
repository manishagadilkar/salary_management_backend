require 'rails_helper'

RSpec.describe Employee, type: :model do
  it "sets full_name before save" do
    emp = Employee.create!(first_name: "John", last_name: "Doe", job_title: "Engineer", country: "US", salary: 70000)
    expect(emp.full_name).to eq("John Doe")
  end
end


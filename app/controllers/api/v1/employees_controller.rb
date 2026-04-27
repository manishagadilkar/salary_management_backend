module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :authenticate_token!
      before_action :set_employee, only: [:show, :update, :destroy]

      # GET /api/v1/employees
      def index
        employees = Employee.all
        employees = employees.by_country(params[:country]) if params[:country].present?
        employees = employees.by_job_title(params[:job_title]) if params[:job_title].present?

        render json: EmployeeSerializer.new(employees).serializable_hash[:data]
      end

      # GET /api/v1/employees/:id
      def show
        render json: EmployeeSerializer.new(@employee).serializable_hash[:data]
      end

      # POST /api/v1/employees
      def create
        employee = Employee.new(employee_params)

        if employee.save
          render json: EmployeeSerializer.new(employee).serializable_hash[:data], status: :created
        else
          render json: { errors: employee.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/employees/:id
      def update
        if @employee.update(employee_params)
          render json: EmployeeSerializer.new(@employee).serializable_hash[:data]
        else
          render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/employees/:id
      def destroy
        @employee.destroy
        head :no_content
      end

      # GET /api/v1/employees/salary_insights
      def salary_insights
        employees = Employee.all
        employees = employees.by_country(params[:country]) if params[:country].present?

        insights = {
          total_employees: employees.count,
          min_salary: employees.minimum(:salary),
          max_salary: employees.maximum(:salary),
          avg_salary: employees.average(:salary).to_f
        }

        if params[:job_title].present?
          job_employees = employees.by_job_title(params[:job_title])
          insights[:job_title_avg_salary] = job_employees.average(:salary).to_f
        end

        render json: insights
      end

      private

      def set_employee
        @employee = Employee.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { message: 'Employee not found' }, status: :not_found
      end

      def employee_params
        params.permit(:first_name, :last_name, :job_title, :country, :salary, :department, :year_started)
      end
    end
  end
end

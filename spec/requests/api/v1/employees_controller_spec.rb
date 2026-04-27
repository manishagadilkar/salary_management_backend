require 'rails_helper'

describe 'Api::V1::EmployeesController', type: :request do
  let(:user) { create(:user) }
  let(:valid_token) { user.generate_token }
  let(:invalid_token) { 'invalid_token' }
  let(:headers) { { 'Authorization' => "Bearer #{valid_token}" } }

  describe 'Authentication' do
    it 'returns 401 when no token is provided' do
      get '/api/v1/employees'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 when invalid token is provided' do
      get '/api/v1/employees', headers: { 'Authorization' => "Bearer #{invalid_token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/employees' do
    context 'with valid token' do
      before do
        @employee1 = create(:employee, first_name: 'John', country: 'USA', job_title: 'Manager')
        @employee2 = create(:employee, first_name: 'Jane', country: 'Canada', job_title: 'Developer')
        @employee3 = create(:employee, first_name: 'Bob', country: 'USA', job_title: 'Developer')
      end

      it 'returns all employees' do
        get '/api/v1/employees', headers: headers
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body).length).to eq(3)
      end

      it 'returns employees with correct attributes' do
        get '/api/v1/employees', headers: headers
        employees = JSON.parse(response.body)
        
        expect(employees[0]).to have_key('first_name')
        expect(employees[0]).to have_key('last_name')
        expect(employees[0]).to have_key('job_title')
        expect(employees[0]).to have_key('country')
        expect(employees[0]).to have_key('salary')
        expect(employees[0]).to have_key('full_name')
      end

      context 'filtering by country' do
        it 'filters employees by country' do
          get '/api/v1/employees?country=USA', headers: headers
          employees = JSON.parse(response.body)
          
          expect(employees.length).to eq(2)
          expect(employees.map { |e| e['country'] }).to all(eq('USA'))
        end

        it 'returns empty array when no employees in country' do
          get '/api/v1/employees?country=UK', headers: headers
          employees = JSON.parse(response.body)
          
          expect(employees.length).to eq(0)
        end
      end

      context 'filtering by job_title' do
        it 'filters employees by job_title' do
          get '/api/v1/employees?job_title=Developer', headers: headers
          employees = JSON.parse(response.body)
          
          expect(employees.length).to eq(2)
          expect(employees.map { |e| e['job_title'] }).to all(eq('Developer'))
        end

        it 'returns empty array when no employees with job_title' do
          get '/api/v1/employees?job_title=CEO', headers: headers
          employees = JSON.parse(response.body)
          
          expect(employees.length).to eq(0)
        end
      end

      context 'filtering by both country and job_title' do
        it 'filters by both country and job_title' do
          get '/api/v1/employees?country=USA&job_title=Developer', headers: headers
          employees = JSON.parse(response.body)
          
          expect(employees.length).to eq(1)
          expect(employees[0]['first_name']).to eq('Bob')
          expect(employees[0]['country']).to eq('USA')
          expect(employees[0]['job_title']).to eq('Developer')
        end
      end
    end
  end

  describe 'GET /api/v1/employees/:id' do
    context 'with valid token' do
      before do
        @employee = create(:employee, first_name: 'John', last_name: 'Doe')
      end

      it 'returns a specific employee' do
        get "/api/v1/employees/#{@employee.id}", headers: headers
        expect(response).to have_http_status(:success)
        
        employee = JSON.parse(response.body)
        expect(employee['first_name']).to eq('John')
        expect(employee['last_name']).to eq('Doe')
        expect(employee['id']).to eq(@employee.id)
      end

      it 'returns 404 when employee not found' do
        get '/api/v1/employees/99999', headers: headers
        expect(response).to have_http_status(:not_found)
        
        response_body = JSON.parse(response.body)
        expect(response_body['message']).to eq('Employee not found')
      end
    end
  end

  describe 'POST /api/v1/employees' do
    context 'with valid token' do
      let(:valid_params) do
        {
          first_name: 'Alice',
          last_name: 'Smith',
          job_title: 'Engineer',
          country: 'USA',
          salary: 75000,
          department: 'Engineering',
          year_started: 2020
        }
      end

      it 'creates a new employee' do
        expect {
          post '/api/v1/employees', 
            params: valid_params, 
            headers: headers
        }.to change(Employee, :count).by(1)
        
        expect(response).to have_http_status(:created)
      end

      it 'returns the created employee' do
        post '/api/v1/employees', 
          params: valid_params, 
          headers: headers
        
        employee = JSON.parse(response.body)
        expect(employee['first_name']).to eq('Alice')
        expect(employee['last_name']).to eq('Smith')
        expect(employee['job_title']).to eq('Engineer')
        expect(employee['salary']).to eq(75000)
      end

      it 'generates full_name automatically' do
        post '/api/v1/employees', 
          params: valid_params, 
          headers: headers
        
        employee = JSON.parse(response.body)
        expect(employee['full_name']).to eq('Alice Smith')
      end

      context 'with invalid params' do
        it 'returns unprocessable_entity when first_name is missing' do
          params = valid_params.except(:first_name)
          
          post '/api/v1/employees', 
            params: params, 
            headers: headers
          
          expect(response).to have_http_status(:unprocessable_entity)
          response_body = JSON.parse(response.body)
          expect(response_body['errors']).to include(include("First name can't be blank"))
        end

        it 'returns unprocessable_entity when last_name is missing' do
          params = valid_params.except(:last_name)
          
          post '/api/v1/employees', 
            params: params, 
            headers: headers
          
          expect(response).to have_http_status(:unprocessable_entity)
          response_body = JSON.parse(response.body)
          expect(response_body['errors']).to include(include("Last name can't be blank"))
        end

        it 'returns unprocessable_entity when job_title is missing' do
          params = valid_params.except(:job_title)
          
          post '/api/v1/employees', 
            params: params, 
            headers: headers
          
          expect(response).to have_http_status(:unprocessable_entity)
          response_body = JSON.parse(response.body)
          expect(response_body['errors']).to include(include("Job title can't be blank"))
        end

        it 'returns unprocessable_entity when country is missing' do
          params = valid_params.except(:country)
          
          post '/api/v1/employees', 
            params: params, 
            headers: headers
          
          expect(response).to have_http_status(:unprocessable_entity)
          response_body = JSON.parse(response.body)
          expect(response_body['errors']).to include(include("Country can't be blank"))
        end

        it 'returns unprocessable_entity when salary is missing' do
          params = valid_params.except(:salary)
          
          post '/api/v1/employees', 
            params: params, 
            headers: headers
          
          expect(response).to have_http_status(:unprocessable_entity)
          response_body = JSON.parse(response.body)
          expect(response_body['errors']).to include(include("Salary can't be blank"))
        end

        it 'does not create employee with invalid params' do
          params = valid_params.except(:first_name)
          
          expect {
            post '/api/v1/employees', 
              params: params, 
              headers: headers
          }.not_to change(Employee, :count)
        end
      end
    end
  end

  describe 'PUT /api/v1/employees/:id' do
    context 'with valid token' do
      before do
        @employee = create(:employee, first_name: 'John', salary: 50000)
      end

      let(:update_params) do
        {
          first_name: 'Jonathan',
          salary: 60000
        }
      end

      it 'updates an existing employee' do
        put "/api/v1/employees/#{@employee.id}", 
          params: update_params, 
          headers: headers
        
        expect(response).to have_http_status(:success)
        
        @employee.reload
        expect(@employee.first_name).to eq('Jonathan')
        expect(@employee.salary).to eq(60000)
      end

      it 'returns the updated employee' do
        put "/api/v1/employees/#{@employee.id}", 
          params: update_params, 
          headers: headers
        
        employee = JSON.parse(response.body)
        expect(employee['first_name']).to eq('Jonathan')
        expect(employee['salary']).to eq(60000)
      end

      it 'updates full_name when first_name changes' do
        put "/api/v1/employees/#{@employee.id}", 
          params: { first_name: 'Jonathan' }, 
          headers: headers
        
        @employee.reload
        expect(@employee.full_name).to eq("Jonathan #{@employee.last_name}")
      end

      it 'returns 404 when employee not found' do
        put '/api/v1/employees/99999', 
          params: update_params, 
          headers: headers
        
        expect(response).to have_http_status(:not_found)
      end

      context 'with invalid params' do
        it 'returns unprocessable_entity when first_name is blank' do
          put "/api/v1/employees/#{@employee.id}", 
            params: { first_name: '' }, 
            headers: headers
          
          expect(response).to have_http_status(:unprocessable_entity)
          response_body = JSON.parse(response.body)
          expect(response_body['errors']).to include(include("First name can't be blank"))
        end

        it 'does not update employee with invalid params' do
          original_name = @employee.first_name
          
          put "/api/v1/employees/#{@employee.id}", 
            params: { first_name: '' }, 
            headers: headers
          
          @employee.reload
          expect(@employee.first_name).to eq(original_name)
        end
      end
    end
  end

  describe 'DELETE /api/v1/employees/:id' do
    context 'with valid token' do
      before do
        @employee = create(:employee)
      end

      it 'deletes an employee' do
        expect {
          delete "/api/v1/employees/#{@employee.id}", 
            headers: headers
        }.to change(Employee, :count).by(-1)
        
        expect(response).to have_http_status(:no_content)
      end

      it 'returns 204 No Content' do
        delete "/api/v1/employees/#{@employee.id}", 
          headers: headers
        
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end

      it 'returns 404 when employee not found' do
        delete '/api/v1/employees/99999', 
          headers: headers
        
        expect(response).to have_http_status(:not_found)
      end

      it 'cannot delete same employee twice' do
        delete "/api/v1/employees/#{@employee.id}", 
          headers: headers
        
        expect(response).to have_http_status(:no_content)
        
        delete "/api/v1/employees/#{@employee.id}", 
          headers: headers
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /api/v1/employees/salary_insights' do
    context 'with valid token' do
      before do
        create(:employee, country: 'USA', job_title: 'Manager', salary: 100000)
        create(:employee, country: 'USA', job_title: 'Developer', salary: 80000)
        create(:employee, country: 'USA', job_title: 'Developer', salary: 90000)
        create(:employee, country: 'Canada', job_title: 'Manager', salary: 95000)
      end

      it 'returns salary insights for all employees' do
        get '/api/v1/employees/salary_insights', 
          headers: headers
        
        expect(response).to have_http_status(:success)
        insights = JSON.parse(response.body)
        
        expect(insights['total_employees']).to eq(4)
        expect(insights).to have_key('min_salary')
        expect(insights).to have_key('max_salary')
        expect(insights).to have_key('avg_salary')
      end

      it 'calculates correct salary statistics' do
        get '/api/v1/employees/salary_insights', 
          headers: headers
        
        insights = JSON.parse(response.body)
        expect(insights['min_salary']).to eq(80000)
        expect(insights['max_salary']).to eq(100000)
        expect(insights['avg_salary']).to be_between(88000, 89000)
      end

      context 'filtering by country' do
        it 'returns salary insights for specific country' do
          get '/api/v1/employees/salary_insights?country=USA', 
            headers: headers
          
          insights = JSON.parse(response.body)
          expect(insights['total_employees']).to eq(3)
          expect(insights['min_salary']).to eq(80000)
          expect(insights['max_salary']).to eq(100000)
        end

        it 'returns empty insights for non-existent country' do
          get '/api/v1/employees/salary_insights?country=UK', 
            headers: headers
          
          insights = JSON.parse(response.body)
          expect(insights['total_employees']).to eq(0)
          expect(insights['min_salary']).to be_nil
          expect(insights['max_salary']).to be_nil
        end
      end

      context 'filtering by job_title' do
        it 'returns job_title_avg_salary when job_title is provided' do
          get '/api/v1/employees/salary_insights?job_title=Developer', 
            headers: headers
          
          insights = JSON.parse(response.body)
          expect(insights).to have_key('job_title_avg_salary')
          expect(insights['job_title_avg_salary']).to be_between(84000, 86000)
        end
      end

      context 'filtering by country and job_title' do
        it 'returns insights with both filters applied' do
          get '/api/v1/employees/salary_insights?country=USA&job_title=Developer', 
            headers: headers
          
          insights = JSON.parse(response.body)
          expect(insights['total_employees']).to eq(3) # All USA employees
          expect(insights['job_title_avg_salary']).to be_between(84000, 86000)
        end
      end
    end
  end
end

require 'rails_helper'

describe Api::V1::AuthenticationController, type: :request do
  let(:base_path) { '/api/v1' }

  describe 'POST /api/v1/login' do
    describe 'with valid credentials' do
      let(:user) { create(:user, email: 'john@example.com', password: 'password123', name: 'John Doe') }

      before { user } # Create user before making request

      it 'returns 200 status' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: 'password123'
          }
        }
        expect(response).to have_http_status(:ok)
      end

      it 'returns JWT token' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: 'password123'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
        expect(json_response['token']).to be_a(String)
      end

      it 'returns user data' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: 'password123'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['user']).to be_present
        expect(json_response['user']['email']).to eq('john@example.com')
        expect(json_response['user']['name']).to eq('John Doe')
      end

      it 'returns correct user attributes' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: 'password123'
          }
        }
        json_response = JSON.parse(response.body)
        user_data = json_response['user']
        
        expect(user_data['id']).to be_present
        expect(user_data['email']).to eq('john@example.com')
        expect(user_data['name']).to eq('John Doe')
        expect(user_data).not_to have_key('password_digest')
      end

      it 'token is valid and decodable' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: 'password123'
          }
        }
        json_response = JSON.parse(response.body)
        token = json_response['token']
        
        decoded = JWT.decode(token, Rails.application.secret_key_base)
        expect(decoded[0]['id']).to eq(user.id)
      end
    end

    describe 'with invalid email' do
      it 'returns 401 status' do
        post "#{base_path}/login", params: {
          user: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        post "#{base_path}/login", params: {
          user: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Invalid credentials')
      end

      it 'does not return token' do
        post "#{base_path}/login", params: {
          user: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response).not_to have_key('token')
      end
    end

    describe 'with invalid password' do
      let(:user) { create(:user, email: 'john@example.com', password: 'password123') }

      before { user }

      it 'returns 401 status' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: 'wrongpassword'
          }
        }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: 'wrongpassword'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Invalid credentials')
      end

      it 'does not return token' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: 'wrongpassword'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response).not_to have_key('token')
      end
    end

    describe 'with missing email' do
      it 'returns 401 status when email is nil' do
        post "#{base_path}/login", params: {
          user: {
            email: nil,
            password: 'password123'
          }
        }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        post "#{base_path}/login", params: {
          user: {
            email: nil,
            password: 'password123'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Invalid credentials')
      end
    end

    describe 'with missing password' do
      let(:user) { create(:user, email: 'john@example.com', password: 'password123') }

      before { user }

      it 'returns 401 status when password is nil' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: nil
          }
        }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: nil
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Invalid credentials')
      end
    end

    describe 'case sensitivity' do
      let(:user) { create(:user, email: 'john@example.com', password: 'password123') }

      before { user }

      it 'login is case sensitive for email' do
        post "#{base_path}/login", params: {
          user: {
            email: 'JOHN@EXAMPLE.COM',
            password: 'password123'
          }
        }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'login is case sensitive for password' do
        post "#{base_path}/login", params: {
          user: {
            email: 'john@example.com',
            password: 'PASSWORD123'
          }
        }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/register' do
    describe 'with valid registration params' do
      it 'returns 201 status' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        expect(response).to have_http_status(:created)
      end

      it 'creates a new user' do
        expect {
          post "#{base_path}/register", params: {
            user: {
              email: 'newuser@example.com',
              password: 'password123',
              name: 'New User'
            }
          }
        }.to change(User, :count).by(1)
      end

      it 'returns JWT token' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
        expect(json_response['token']).to be_a(String)
      end

      it 'returns user data' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['user']).to be_present
        expect(json_response['user']['email']).to eq('newuser@example.com')
        expect(json_response['user']['name']).to eq('New User')
      end

      it 'returns correct user attributes' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        user_data = json_response['user']
        
        expect(user_data['id']).to be_present
        expect(user_data['email']).to eq('newuser@example.com')
        expect(user_data['name']).to eq('New User')
        expect(user_data).not_to have_key('password_digest')
      end

      it 'token is valid and decodable' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        token = json_response['token']
        
        decoded = JWT.decode(token, Rails.application.secret_key_base)
        expect(decoded[0]['id']).to be_present
      end

      it 'sets default role to user' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        user_data = json_response['user']
        expect(user_data['role']).to eq('user')
      end

      it 'encrypts password' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        created_user = User.find_by(email: 'newuser@example.com')
        expect(created_user.password_digest).to be_present
        expect(created_user.password_digest).not_to eq('password123')
      end
    end

    describe 'with missing email' do
      it 'returns 422 status' do
        post "#{base_path}/register", params: {
          user: {
            email: nil,
            password: 'password123',
            name: 'New User'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        post "#{base_path}/register", params: {
          user: {
            email: nil,
            password: 'password123',
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']).to include("Email can't be blank")
      end

      it 'does not create user' do
        expect {
          post "#{base_path}/register", params: {
            user: {
              email: nil,
              password: 'password123',
              name: 'New User'
            }
          }
        }.not_to change(User, :count)
      end

      it 'does not return token' do
        post "#{base_path}/register", params: {
          user: {
            email: nil,
            password: 'password123',
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response).not_to have_key('token')
      end
    end

    describe 'with missing password' do
      it 'returns 422 status' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: nil,
            name: 'New User'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: nil,
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']).to include("Password can't be blank")
      end

      it 'does not create user' do
        expect {
          post "#{base_path}/register", params: {
            user: {
              email: 'newuser@example.com',
              password: nil,
              name: 'New User'
            }
          }
        }.not_to change(User, :count)
      end
    end

    describe 'with missing name' do
      it 'returns 422 status' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: nil
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: nil
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']).to include("Name can't be blank")
      end

      it 'does not create user' do
        expect {
          post "#{base_path}/register", params: {
            user: {
              email: 'newuser@example.com',
              password: 'password123',
              name: nil
            }
          }
        }.not_to change(User, :count)
      end
    end

    describe 'with duplicate email' do
      let(:existing_user) { create(:user, email: 'existing@example.com') }

      before { existing_user }

      it 'returns 422 status' do
        post "#{base_path}/register", params: {
          user: {
            email: 'existing@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns uniqueness error message' do
        post "#{base_path}/register", params: {
          user: {
            email: 'existing@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']).to include('Email has already been taken')
      end

      it 'does not create another user' do
        expect {
          post "#{base_path}/register", params: {
            user: {
              email: 'existing@example.com',
              password: 'password123',
              name: 'New User'
            }
          }
        }.not_to change(User, :count)
      end
    end

    describe 'with short password' do
      it 'returns 422 status' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: '12345',
            name: 'New User'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns length validation error' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: '12345',
            name: 'New User'
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']).to include('Password is too short (minimum is 6 characters)')
      end

      it 'does not create user' do
        expect {
          post "#{base_path}/register", params: {
            user: {
              email: 'newuser@example.com',
              password: '12345',
              name: 'New User'
            }
          }
        }.not_to change(User, :count)
      end
    end

    describe 'with multiple validation errors' do
      it 'returns 422 status' do
        post "#{base_path}/register", params: {
          user: {
            email: nil,
            password: nil,
            name: nil
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns all error messages' do
        post "#{base_path}/register", params: {
          user: {
            email: nil,
            password: nil,
            name: nil
          }
        }
        json_response = JSON.parse(response.body)
        expect(json_response['errors'].length).to be >= 3
      end
    end
  end

  describe 'Authentication middleware' do
    describe 'skip_before_action for login and register' do
      it 'login does not require authentication token' do
        post "#{base_path}/login", params: {
          user: {
            email: 'test@example.com',
            password: 'password123'
          }
        }
        # Should not get 401 due to missing token
        expect(response).not_to have_http_status(401)
      end

      it 'register does not require authentication token' do
        post "#{base_path}/register", params: {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: 'New User'
          }
        }
        # Should not get 401 due to missing token
        expect(response).not_to have_http_status(401)
      end
    end
  end

  describe 'Response format and serialization' do
    let(:user) { create(:user, email: 'john@example.com', password: 'password123', name: 'John Doe') }

    before { user }

    it 'login response has correct JSON structure' do
      post "#{base_path}/login", params: {
        user: {
          email: 'john@example.com',
          password: 'password123'
        }
      }
      json_response = JSON.parse(response.body)
      
      expect(json_response).to have_key('token')
      expect(json_response).to have_key('user')
      expect(json_response['user']).to be_a(Hash)
    end

    it 'register response has correct JSON structure' do
      post "#{base_path}/register", params: {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          name: 'New User'
        }
      }
      json_response = JSON.parse(response.body)
      
      expect(json_response).to have_key('token')
      expect(json_response).to have_key('user')
      expect(json_response['user']).to be_a(Hash)
    end

    it 'does not return password_digest in login response' do
      post "#{base_path}/login", params: {
        user: {
          email: 'john@example.com',
          password: 'password123'
        }
      }
      json_response = JSON.parse(response.body)
      expect(json_response['user']).not_to have_key('password_digest')
    end

    it 'does not return password_digest in register response' do
      post "#{base_path}/register", params: {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          name: 'New User'
        }
      }
      json_response = JSON.parse(response.body)
      expect(json_response['user']).not_to have_key('password_digest')
    end
  end
end

require 'rails_helper'

describe User do
  describe 'associations' do
    it { is_expected.to have_secure_password }
  end

  describe 'validations' do
    describe 'email validation' do
      it 'validates presence of email' do
        user = build(:user, email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'validates uniqueness of email' do
        create(:user, email: 'test@example.com')
        user = build(:user, email: 'test@example.com')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('has already been taken')
      end

      it 'accepts valid email' do
        user = build(:user, email: 'valid@example.com')
        expect(user).to be_valid
      end
    end

    describe 'password validation' do
      it 'validates presence of password' do
        user = build(:user, password: nil)
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end

      it 'validates minimum length of password' do
        user = build(:user, password: '12345')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
      end

      it 'accepts password with minimum 6 characters' do
        user = build(:user, password: '123456')
        expect(user).to be_valid
      end

      it 'accepts password longer than 6 characters' do
        user = build(:user, password: 'securepassword123')
        expect(user).to be_valid
      end
    end

    describe 'name validation' do
      it 'validates presence of name' do
        user = build(:user, name: nil)
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include("can't be blank")
      end

      it 'accepts valid name' do
        user = build(:user, name: 'John Doe')
        expect(user).to be_valid
      end
    end
  end

  describe 'enums' do
    it 'defines role enum with user and admin values' do
      user = create(:user, role: :user)
      expect(user.role).to eq('user')
      expect(user).to be_user

      admin = create(:user, role: :admin)
      expect(admin.role).to eq('admin')
      expect(admin).to be_admin
    end

    it 'defaults to user role' do
      user = create(:user)
      expect(user.role).to eq('user')
    end
  end

  describe '#generate_token' do
    let(:user) { create(:user) }

    it 'generates a valid JWT token' do
      token = user.generate_token
      expect(token).to be_present
      expect(token).to be_a(String)
    end

    it 'includes user id in token payload' do
      token = user.generate_token
      decoded = JWT.decode(token, Rails.application.secret_key_base)
      expect(decoded[0]['id']).to eq(user.id)
    end

    it 'includes expiration time in token' do
      token = user.generate_token
      decoded = JWT.decode(token, Rails.application.secret_key_base)
      expect(decoded[0]['exp']).to be_present
      expect(decoded[0]['exp']).to be > Time.now.to_i
    end

    it 'token expires in 24 hours' do
      token = user.generate_token
      decoded = JWT.decode(token, Rails.application.secret_key_base)
      exp_time = Time.at(decoded[0]['exp'])
      current_time = Time.now
      time_difference = (exp_time - current_time).abs
      
      # Allow 1 minute buffer for test execution
      expect(time_difference).to be_between(23.hours, 24.hours + 60.seconds)
    end

    it 'generates different tokens for different calls' do
      token1 = user.generate_token
      sleep(0.1)
      token2 = user.generate_token
      expect(token1).not_to eq(token2)
    end
  end

  describe '.decode_token' do
    let(:user) { create(:user) }
    let(:token) { user.generate_token }

    it 'decodes a valid token and returns the user' do
      decoded_user = User.decode_token(token)
      expect(decoded_user).to eq(user)
      expect(decoded_user.id).to eq(user.id)
    end

    it 'returns nil for invalid token' do
      invalid_token = 'invalid_token_string'
      result = User.decode_token(invalid_token)
      expect(result).to be_nil
    end

    it 'returns nil for expired token' do
      # Create a token with immediate expiration
      expired_token = JWT.encode(
        { id: user.id, exp: (Time.now - 1.hour).to_i },
        Rails.application.secret_key_base
      )
      result = User.decode_token(expired_token)
      expect(result).to be_nil
    end

    it 'returns nil for token with non-existent user id' do
      invalid_token = JWT.encode(
        { id: 99999, exp: 24.hours.from_now.to_i },
        Rails.application.secret_key_base
      )
      result = User.decode_token(invalid_token)
      expect(result).to be_nil
    end

    it 'returns nil for token with wrong secret key' do
      token_with_wrong_key = JWT.encode(
        { id: user.id, exp: 24.hours.from_now.to_i },
        'wrong_secret_key'
      )
      result = User.decode_token(token_with_wrong_key)
      expect(result).to be_nil
    end

    it 'handles JWT decode error gracefully' do
      # Malformed token
      malformed_token = 'malformed.token.here'
      result = User.decode_token(malformed_token)
      expect(result).to be_nil
    end
  end

  describe 'password encryption' do
    it 'encrypts password on save' do
      user = create(:user, password: 'plainpassword123')
      expect(user.password_digest).not_to eq('plainpassword123')
      expect(user.password_digest).to be_present
    end

    it 'authenticates with correct password' do
      user = create(:user, password: 'correctpassword123')
      expect(user.authenticate('correctpassword123')).to eq(user)
    end

    it 'fails authentication with incorrect password' do
      user = create(:user, password: 'correctpassword123')
      expect(user.authenticate('wrongpassword123')).to be_falsey
    end
  end

  describe 'user creation' do
    it 'creates a user with valid attributes' do
      user = create(:user, 
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        role: :user
      )
      expect(user).to be_persisted
      expect(user.name).to eq('John Doe')
      expect(user.email).to eq('john@example.com')
      expect(user.role).to eq('user')
    end

    it 'does not create user with invalid attributes' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect { user.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'scopes and queries' do
    before do
      @admin_user = create(:user, role: :admin)
      @regular_user = create(:user, role: :user)
      @another_user = create(:user, role: :user)
    end

    it 'can filter users by role' do
      admins = User.where(role: 'admin')
      expect(admins.count).to eq(1)
      expect(admins.first).to eq(@admin_user)
    end

    it 'can find user by email' do
      user = User.find_by(email: @regular_user.email)
      expect(user).to eq(@regular_user)
    end
  end
end

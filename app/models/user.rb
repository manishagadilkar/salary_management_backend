class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }
  validates :name, presence: true

  enum :role, { user: 'user', admin: 'admin' }

  def generate_token
    JWT.encode({ id: id, exp: 24.hours.from_now.to_i }, Rails.application.secret_key_base)
  end

  def self.decode_token(token)
    decode = JWT.decode(token, Rails.application.secret_key_base)
    self.find(decode[0]['id'])
  rescue
    nil
  end
end
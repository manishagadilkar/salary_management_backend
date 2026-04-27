class Employee < ApplicationRecord
  before_save :set_full_name
  validates :first_name, :last_name, :job_title, :country, :salary, presence: true
  scope :by_country, ->(country) { where(country: country) }
  private
  def set_full_name
    self.full_name = "#{first_name} #{last_name}"
  end
end
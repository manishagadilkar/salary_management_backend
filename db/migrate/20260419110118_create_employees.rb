class CreateEmployees < ActiveRecord::Migration[7.2]
  def change
    create_table :employees do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :full_name
      t.string :emp_id, null: false
      t.string :job_title, null: false
      t.string :country, null: false
      t.decimal :salary, precision: 15, scale: 2
      t.string :department
      t.integer :year_started

      t.timestamps
    end
    add_index :employees, :country
    add_index :employees, :job_title
    add_index :employees, :department
    add_index :employees, :emp_id, unique: true
  end
end

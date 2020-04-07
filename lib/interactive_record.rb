require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'
class InteractiveRecord
  def self.table_name 
    self.to_s.downcase.pluralize
  end
  
  def self.column_names 
    # Makes it so we can access returned SQL queries as hashes
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{table_name}')"
    
    table_info = DB[:conn].execute(sql)
    column_names = []
    
    table_info.each do |column|
      column_names << column["name"]
    end
    column_names.compact
  end 
  
  def initialize(attributes={})
    attributes.each do |property, value|
      self.send("#{property}=", value)
    end
  end
  
  def table_name_for_insert 
    self.class.table_name
  end
  
  def col_names_for_insert 
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end
  
  def values_for_insert 
    values = []
    self.class.column_names.each do |column_name|
      values << "'#{send(column_name)}'" unless send(column_name).nil?
    end
    values.join(", ")
  end
  
  def save 
    DB[:conn].execute("INSERT INTO #{self.table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert});")
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert};")[0][0]
  end
  
  def self.find_by_name(name) 
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", name)
  end

  def self.find_by(attribute)
    property = attribute.first[0]
    value = attribute.first[1]
    if(value.class == Integer)
      DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{property} = ?", value)
    else
      self.find_by_name(property.to_s)
    end
  end
end
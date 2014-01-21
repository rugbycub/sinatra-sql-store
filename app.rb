require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'pg'


def dbname
  "storeadminsite"
end

def with_db
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  yield c
  c.close
end

get '/' do
  erb :index
end

# The Products machinery:

# Get the index of products
get '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  # Get all rows from the products table.
  @products = c.exec_params("SELECT * FROM products;")
  c.close
  erb :products
end

# Get the form for creating a new product
get '/products/new' do
  @categories = (c.exec_params("SELECT * FROM categories;")).to_a
  puts @categories
  erb :new_product
end

# POST to create a new product
post '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO products (name, price, description) VALUES ($1,$2,$3)",
                  [params["name"], params["price"], params["description"]])

  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_product_id = c.exec_params("SELECT currval('products_id_seq');").first["currval"]
  c.close
  redirect "/products/#{new_product_id}"
end

# Update a product
post '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Update the product.
  c.exec_params("UPDATE products SET (name, price, description) = ($2, $3, $4) WHERE products.id = $1 ",
                [params["id"], params["name"], params["price"], params["description"]])
  c.close
  redirect "/products/#{params["id"]}"
end

get '/products/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1", [params["id"]]).first
  c.close
  erb :edit_product
end
# DELETE to delete a product
post '/products/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec_params("DELETE FROM products WHERE products.id = $1", [params["id"]])
  c.close
  redirect '/products'
end

# GET the show page for a particular product
get '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1;", [params[:id]]).first
  @associated_categories = (c.exec_params("SELECT c.name AS Categories FROM products AS p INNER JOIN product_categories AS pc ON pc.product_id = p.id INNER JOIN categories AS c ON pc.category_id=c.id WHERE p.id = $1;", [params[:id]])).to_a
  c.close
  erb :product
end


get '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the products table.
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :categories
end


get '/categories' do
  @products = Array.new
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the products table.
  @categories = c.exec_params("SELECT * FROM products;")
  products = c.exec_params("SELECT * FROM categories;").to_a
  products.each do |category|
    @products << category["name"]
  end
  puts @products
  c.close
  erb :categories
end

# Get the form for creating a new product
get '/categories/new' do
  erb :new_category
end

post '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO categories (name) VALUES ($1)",
                  [params["name"]])

  new_category_id = c.exec_params("SELECT currval('categories_id_seq');").first["currval"]
  c.close
  redirect "/categories/#{new_category_id}"
end

# Update a product
post '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Update the product.
  c.exec_params("UPDATE categories SET (name) = ($2) WHERE products.id = $1 ",
                [params["id"], params["name"]])
  c.close
  redirect "/categories/#{params["id"]}"
end

get '/categories/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @category = c.exec_params("SELECT name FROM categories WHERE categories.id = $1", [params["id"]]).first
  c.close
  erb :edit_category
end
# DELETE to delete a product
post '/categories/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec_params("DELETE FROM categories WHERE categories.id = $1", [params["id"]])
  c.close
  redirect '/categories'
end

# GET the show page for a particular product
get '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @category = c.exec_params("SELECT * FROM categories WHERE categories.id = $1;", [params[:id]]).first
  @associated_products = c.exec_params("SELECT p.name AS Products FROM products AS p INNER JOIN product_categories AS pc ON pc.product_id = p.id INNER JOIN categories AS c ON pc.category_id=c.id WHERE c.id = $1;", [params[:id]])
  c.close
  erb :category
end





















def create_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
  CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    price decimal,
    description text
  );
  }
  c.close
end

def drop_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec "DROP TABLE products;"
  c.close
end

def seed_products_table
  products = [["Laser", "325", "Good for lasering."],
              ["Shoe", "23.4", "Just the left one."],
              ["Wicker Monkey", "78.99", "It has a little wicker monkey baby."],
              ["Whiteboard", "125", "Can be written on."],
              ["Chalkboard", "100", "Can be written on.  Smells like education."],
              ["Podium", "70", "All the pieces swivel separately."],
              ["Bike", "150", "Good for biking from place to place."],
              ["Kettle", "39.99", "Good for boiling."],
              ["Toaster", "20.00", "Toasts your enemies!"],
             ]

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  products.each do |p|
    c.exec_params("INSERT INTO products (name, price, description) VALUES ($1, $2, $3);", p)
  end
  c.close
end

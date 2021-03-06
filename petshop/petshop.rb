require "pg"
require "json"
require "rest-client"

class PetshopSetup
  def initialize
    # connection to database
    @db = PG::Connection.open(dbname: 'petshop')
    # database tables
    @shops_table = "petshops"
    @dogs_table = "dogs"
    @cats_table = "cats"
    # api url
    @api = "http://pet-shop.api.mks.io/"
    # api resources
    @shops = "shops/"
    @cats = "cats/"
    @dogs = "dogs/"
    
  end

  # create database tables
  def make_tables
    sql_create_petshops = %Q[
      create table if not exists #{@shops_table}
      (id integer primary key, 
      name varchar not null
      )
    ]

    sql_create_cats = %Q[
      create table if not exists #{@cats_table}
      (id integer primary key, 
      name varchar not null,
      image_url varchar null,
      adopted varchar null,
      shop_id integer references petshops
      )
    ]

    sql_create_dogs = %Q[
      create table if not exists #{@dogs_table}
      (id integer primary key,
      name varchar not null,
      image_url varchar null,
      happiness integer constraint five_or_less check (happiness <= 5),
      adopted varchar null,
      shop_id integer references petshops
      )
    ]
    
    @db.exec(sql_create_petshops)
    @db.exec(sql_create_cats)
    @db.exec(sql_create_dogs)
  end

  # populate petshops table
  def populate_petshops
    result =  JSON.parse(RestClient.get @api + @shops)
    
    # prepared statement
    statement_insert_shop = %Q[ 
        insert into #{@shops_table}
        (id, name)
        values ($1, $2)
      ]
    @db.prepare("insert_shops", statement_insert_shop)

    # populate table using prepared statement  
    result.each do |shop|
      @db.exec_prepared("insert_shops", [shop["id"], shop["name"]])
    end
  end

  # populate cats table
  def populate_cats
    # prepared statement
    statement_insert_shop = %Q[ 
        insert into #{@cats_table}
        (id, name, image_url, adopted, shop_id)
        values ($1, $2, $3, $4, $5)
      ]
    @db.prepare("insert_cats", statement_insert_shop)

    # query for existing shops
    sql_shops = %Q[select * from #{@shops_table}]
    result_shops = @db.exec(sql_shops)

    # iterate through shops
    result_shops.each do |shop|
      result_cats = JSON.parse(RestClient.get @api + @shops + shop["id"] + "/" + @cats)

      # populate table using prepared statement  
      result_cats.each do |cat|
        @db.exec_prepared("insert_cats", [cat["id"].to_i, cat["name"], cat["imageUrl"], cat["adopted"], cat["shopId"].to_i])
      end
    end
  end

  # populate dogs table
  def populate_dogs
    # prepared statement
    statement_insert_shop = %Q[ 
        insert into #{@dogs_table}
        (id, name, image_url, happiness, adopted, shop_id)
        values ($1, $2, $3, $4, $5, $6)
      ]
    @db.prepare("insert_dogs", statement_insert_shop)

    # query for existing shops
    sql_shops = %Q[select * from #{@shops_table}]
    result_shops = @db.exec(sql_shops)

    # iterate through shops
    result_shops.each do |shop|
      result_cats = JSON.parse(RestClient.get @api + @shops + shop["id"] + "/" + @dogs)

      # populate table using prepared statement  
      result_cats.each do |dog|
        @db.exec_prepared("insert_dogs", [dog["id"].to_i, dog["name"], dog["imageUrl"], dog["happiness"].to_i, dog["adopted"], dog["shopId"].to_i])
      end
    end
  end

  # retrieve all pet shops
  def all_petshops
    sql = %Q[
      select * from #{@shops_table}
    ]

    # output a header
    puts "ID   |   Name"
    puts "------------------------"

    # execute query and iterate through the result set
    results = @db.exec(sql)
    results.each do |shop|
      puts "#{shop["id"]}    |   #{shop["name"]}"
    end
  end

  # retrieve dogs for a particular shop
  def all_dogs_for_shop shop_id
    sql_dogs = %Q[
      select dogs.name, happiness, adopted
      from #{@dogs_table}
      where shop_id = #{shop_id}
    ]

    sql_shop = %Q[
      select *
      from #{@shops_table}
      where id = #{shop_id}
    ]

    #excute query for shop and output shop name as header
    results_shop = @db.exec(sql_shop)
    results_shop.each do |shop|
      puts "Dogs in #{shop["name"]}:"
      puts "===================================="
    end

    # execute query and iterate through the result set
    results_dogs = @db.exec(sql_dogs)
    results_dogs.each do |dog|
      puts "Name: #{dog["name"]}"
      puts "Happiness: #{dog["happiness"]}"
      puts "Adopted: #{dog["adopted"]}"
      puts "------------------------------------"
    end
  end

  # restrieve happiest dogs
  def happiest_dogs
    sql = %Q[
      select name, happiness
      from #{@dogs_table}
      order by happiness desc, name asc
      limit 5
    ]

    # output a header
    puts "Happiest Dogs:"
    # execute query and iterate over results
    results = @db.exec(sql)
    results.each do |dog|
      puts "#{dog["name"]} - #{dog["happiness"]}"
    end
  end

  # retrieve all pets
  def all_pets
    sql = %Q[
      SELECT dogs.name as pet_name, petshops.name as shop_name
      FROM dogs  
      JOIN petshops  
      ON dogs.shop_id = petshops.id 
      UNION  
      SELECT cats.name pet_name, petshops.name as shop_name
      FROM cats  
      JOIN petshops  
      ON cats.shop_id = petshops.id 
      order by pet_name
    ]

    # output a header
    puts "Pet Name     |  Pet Shop"
    puts "============================"

    # execute query and iterate over results
    results = @db.exec(sql)
    results.each do |pet|
      puts "#{pet["pet_name"]}  |  #{pet["shop_name"]}"
    end
  end

end 

petshop = PetshopSetup.new

# petshop.make_tables
# petshop.populate_petshops
# petshop.populate_cats
# petshop.populate_dogs
#petshop.all_petshops
#petshop.all_dogs_for_shop 14
#petshop.happiest_dogs
petshop.all_pets
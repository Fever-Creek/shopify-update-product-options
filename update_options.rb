#!/bin/ruby
require 'shopify_api'

def updateSize(currentSize,gender)
  puts "gender #{gender} - currentSize: #{currentSize}"
  accepted_sizes = ['0','1','2','3','4','5']

  if accepted_sizes.include?(currentSize)
    puts "yes it's gonna update!"

    case currentSize.to_i
    when 0
      if gender == 'mens'
        return 'XS'
      elsif gender == 'womens'
        return 'XXS'
      else
        return 'none'
      end
    when 1
      if gender == 'mens'
        return 'S'
      elsif gender == 'womens'
        return 'XS'
      else
        return 'none'
      end
    when 2
      if gender == 'mens'
        return 'M'
      elsif gender == 'womens'
        return 'S'
      else
        return 'none'
      end
    when 3
      if gender == 'mens'
        return 'L'
      elsif gender == 'womens'
        return 'M'
      else
        return 'none'
      end
    when 4
      if gender == 'mens'
        return 'XL'
      elsif gender == 'womens'
        return 'L'
      else
        return 'none'
      end
    when 5
      if gender == 'mens'
        return 'XXL'
      elsif gender == 'womens'
        return 'XL'
      else
        return 'none'
      end
    else
      puts "Error: #{currentSize}"
      return 'none'
    end
  else
    puts "No it's not gonna update. #{currentSize}"
    return 'none'
  end
end

print "[S]imulate or [R]un? : "
STDOUT.flush
input_var = STDIN.gets.chomp

# Initializing a timer.
script_start_time = Time.now

# You can average 2 calls per second
CYCLE = 60

# Define authentication parameters.
# From config.rb file
config_file = './config.rb'
require config_file if File.file? config_file

if input_var == "S"
  puts "Store "
  puts SOURCE_SHOPIFY_SHOP
elsif input_var == "R"

    total_api_calls = 0

    # Configure the Shopify API with our authentication credentials.
    ShopifyAPI::Base.site = "https://#{SOURCE_SHOPIFY_API_KEY}:#{SOURCE_SHOPIFY_PASSWORD}@#{SOURCE_SHOPIFY_SHOP}/admin"

    # How many products for pagination
    product_count = ShopifyAPI::Product.count
    nb_pages      = (product_count / 250.0).ceil
    puts "You're shop has #{product_count} products! So we're breaking it up into #{nb_pages} pages."

    # Initializing.
    start_time = Time.now

    # While we still have products.
    1.upto(nb_pages) do |page|

      unless page == 1 # start unless page 1
        stop_time = Time.now
        puts "Current batch processing started at #{start_time.strftime('%I:%M%p')}"
        puts "The time is now #{stop_time.strftime('%I:%M%p')}"
        processing_duration = stop_time - start_time
        puts "The processing lasted #{processing_duration.to_i} seconds."
        if processing_duration.to_i > CYCLE
          puts "The duration was longer than the CYCLE (#{CYCLE} seconds). No wait needed."
        else
          wait_time = (CYCLE - processing_duration).ceil
          puts "We have to wait #{wait_time.to_i} seconds then we will resume."
          sleep wait_time
        end
        start_time = Time.now
      end # end unless page 1

      puts "Doing page #{page}/#{nb_pages}..."
      products = ShopifyAPI::Product.find( :all, :params => { :limit => 250, :page => page } )
      products.each do |product| #loop through products

        # output some info for reference
        puts product.handle

        size_option_exists = false
        size_option_position = 0
        gender = 'mens'

        #Check if product has a size option
        product.options.each_with_index do |option, index|
          if option.name.downcase == "size"
            size_option_exists = true
            size_option_position = option.position
            break
          end
        end

        # If the product has the Size option then loop through variants
        if size_option_exists
          puts "size_option_exists"
          new_size = "none"

          #get the gender from the tags
          tags = product.tags.downcase.split(',').map(&:strip)
          if tags.include?('womens')
            gender = 'womens'
          elsif tags.include?('mens')
            gender = 'mens'
          else
            gender = 'none'
          end

          puts gender

          product.variants.each_with_index do |variant, index|

            if size_option_position == 1
              puts "send option1 #{variant.option1}"
              new_size = updateSize(variant.option1,gender)
              unless new_size == "none"
                variant.option1 = "#{new_size}"
              end
            elsif size_option_position == 2
              puts "send option2 #{variant.option2}"
              new_size = updateSize(variant.option2,gender)
              unless new_size == "none"
                variant.option2 = "#{new_size}"
              end
            elsif size_option_position == 3
              puts "send option3 #{variant.option3}"
              new_size = updateSize(variant.option3,gender)
              unless new_size == "none"
                variant.option3 = "#{new_size}"
              end
            else
              puts "No option position?"
            end
            puts "new_size #{new_size}"

          end # end each variants

          #save the product if the new size is legit
          unless new_size == "none"
            product.save
            total_api_calls += 1
            puts "API calls: #{total_api_calls}"
            # exit
          end

        else
          puts "Size Option Doesn't Exist"
        end

        puts ""

      end # end products.each loop
    end #end page loop

  puts "end"

  script_stop_time = Time.now
  script_processing_duration_seconds = script_stop_time - script_start_time
  script_processing_duration = Time.at(script_processing_duration_seconds).utc.strftime("%H:%M:%S")
  puts "The script took a total of #{script_processing_duration} to complete."

end

namespace :searchkick do
  desc "Reindex all searchkick models"
  task reindex: :environment do
    puts "Reindexing Recipe data..."
    Recipe.reindex
    puts "Done!"
  end
end

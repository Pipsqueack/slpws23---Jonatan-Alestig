require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'

get('/')  do
    
    slim(:start)
end 

helpers do
    def emil
        db = SQLite3::Database.new("db/data.db")
        db.results_as_hash = true
        result = db.execute("SELECT * FROM Inspo_text")

        return result
    end
end

get('your_lyrics') do
    db = SQLite3::Database.new("db/data.db")
    db.results_as_hash = true
    id = session[]
    result = db.execute("SELECT * FROM texts WHERE user_id = ?", id)
    slim(:"your_lyrics/index")
end

get('/login') do
    dataName = params[:username]
    dataPassword = params[:password]
    slim(:login)

end


get('/sign_up') do
    dataFirstName = params[:firstName]
    dataLastName = params[:lastName]
    dataPassword = params[:password]
  
    slim(:sign_up)
end

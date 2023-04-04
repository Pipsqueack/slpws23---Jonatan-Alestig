require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/')  do
    slim(:start)
end 

get('/sign_up') do
  slim(:sign_up)
end

post('/sign_up') do
  username = params[:username]
  password = params[:password]
  password_confirmation = params[:password_confirmation]

  db = SQLite3::Database.new("db/data.db")
  db.results_as_hash = true
  result = db.execute("SELECT user_id FROM User WHERE username=?", username)
    
  if result.empty?
      if password == password_confirmation
        password_digest = BCrypt::Password.create(password)
        p password_digest
        db.execute("INSERT INTO User(username, password_digest) VALUES (?,?)", [username, password_digest])
        
      flash[:notice] = "Registration succesful"
      redirect('/')
      else 
        flash[:warning] = "Passwords do not match"

        redirect('/sign_up')
      end
  else
    flash[:warning] = "Username already exists"

    redirect('/sign_up')
  end
end

get('/login') do
  slim(:login)
end  

post('/login') do
  username = params[:username]
  password = params[:password]

  db = SQLite3::Database.new("db/data.db")
  db.results_as_hash = true
  result = db.execute("SELECT user_id, password_digest FROM User WHERE username=?", [username])

  if result.empty?
    session[:alert] = "Invalid credentials" 
    redirect('/login')
  end

  user_id = result.first["user_id"]
  password_digest = result.first["password_digest"]
  if BCrypt::Password.new(password_digest) == password
      session[:user_id] = user_id
      session[:username] = username

      session[:alert] = "Login succesful"

      redirect('/')
  else
    session[:alert] = "Invalid credentials"
    redirect('/login')
  end
end

post('/logout') do
    session.delete(:user_id)
    session.delete(:username)
    redirect('/')
end


helpers do
    def inspo_func
        db = SQLite3::Database.new("db/data.db")
        db.results_as_hash = true
        result = db.execute("SELECT * FROM Inspo_text WHERE inspo_text_id = ?", rand(1..5)).first

        return result
    end
end

get('/your_lyrics') do
    db = SQLite3::Database.new("db/data.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM texts WHERE user_id = ?", session[:user_id])
    slim(:"your_lyrics/index",locals:{result:result})
end
  
  post('/new_text') do


    text_id = params[:text_id]
    text_content = params[:text_content]
    title = params[:title]
    user_id = session[:user_id]

    if text_content.empty?
      session[:alert] = "Text is empty"
      redirect('/your_lyrics')
    end

    if title.empty?
      session[:alert] = "No title" 
      redirect('/your_lyrics')
    end

    db = SQLite3::Database.new("db/data.db")
    db.execute("INSERT INTO Texts (text_content, title, user_id) VALUES (?,?,?)", text_content, title, user_id)
    redirect('/your_lyrics') 
  end
  
  post('/albums/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/data.db")
    db.execute("DELETE FROM albums WHERE AlbumId = ?",id)
    redirect('/albums')
  end
  
  post('/albums/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    artist_id = params[:artistId].to_i
    db = SQLite3::Database.new("db/data.db")
    db.execute("UPDATE Albums SET Title = ?,ArtistId = ? WHERE AlbumId = ?",title, artist_id, id)
    redirect('/albums')
  end
  
  get('/albums/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/data.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
    slim(:"/albums/edit",locals:{result:result})
  end
  
  get('/albums/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/data.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
    result2 = db.execute("SELECT Name FROM Artists WHERE ArtistID IN (SELECT ArtistID FROM Albums WHERE AlbumID = ?)", id).first
    slim(:"albums/show",locals:{result:result,result2:result2})
  end


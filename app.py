import sqlite3
from  book_search import BookSearch
from flask import Flask, render_template, url_for, flash, redirect, session, g
from flask import request as req
from db_connector import get_db, BookSwapDatabase, get_bsdb
from forms import RegistrationForm, LoginForm, BookSearchForm
from auth import login_required, guest_required

app = Flask(__name__)
# Secret Key for Flask Forms security
app.config['SECRET_KEY'] = '31c46d586e5489fa9fbc65c9d8fd21ed'


# Auto-closes db connection at the end of each request
@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()


# Landing Page
@app.route('/')
@app.route('/home')
@app.route('/index')
def home():
    return render_template('home.html')


@app.route('/learn-how')
def learnHow():
    return render_template('learn-how.html')


@app.route('/faq')
def faq():
    return render_template('faq.html')


@app.route('/browse-books', methods=['GET', 'POST'])
def browseBooks():
    form = BookSearchForm()
    bsdb = get_bsdb()
    recent_books = bsdb.get_recent_additions(5)
    if req.method=='POST':
        book_search_query = (form.ISBN.data, form.author.data, form.title.data)
        book_search = BookSearch(book_search_query, bsdb)
        book_results = book_search.local_book_search(10)
        show_recent = False 
        show_search = False 
        show_results = True
    else:
        book_results = {}
        show_recent = True
        show_search = True
        show_results = False

    print("App.py: BrowseBooks:")
    print(f"\t recent_books: {recent_books}")
    print(f"\t book_results: {book_results}")
    print(f"\t form: {form}")
    return render_template('browse-books.html', 
            recent_books = recent_books, 
            book_results = book_results, 
            form = form,
            show_recent= show_recent,
            show_search = show_search,
            show_results = show_results
            )

@app.route('/my-trades')
def myTrades():
    return render_template('user/my-trades.html')


@app.route('/login', methods=['GET', 'POST'])
@guest_required
def login():
    form = LoginForm()
    # Checks if input is valid
    if form.validate_on_submit():
        username = form.username.data
        password = form.password.data
        error = None

        db = get_db()
        db.row_factory = sqlite3.Row
        # Username check
        user = db.execute("SELECT * FROM Users WHERE username = ?",
                          (username,)).fetchone()
        if user is None:
            user = db.execute("SELECT * FROM Users WHERE email = ?",
                              (username, )).fetchone()
            if user is None:
                error = "Incorrect username."

        # Password check
        elif user['password'] != password:
            error = "Incorrect password."

        # No errors, login proceeds
        if error is None:
            session.clear()
            session['user_num'] = user['id']
            return redirect(url_for('home'))

        flash(error, 'warning')

    """
    # Simulation of a successful login - sample email and password
    if form.email.data == 'admin@bookswap.com' and form.password.data == 'password':
        flash('You have been logged in!', 'success')
        return redirect(url_for('userHome'))
    else:
        flash('Login Unsuccessful. Please check username and password.', 'danger')
    """
    return render_template('login.html', form=form)


@app.route('/signup', methods=['GET', 'POST'])
@guest_required
def signup():
    form = RegistrationForm()
    if form.validate_on_submit():
        db = get_db()
        # db.row_factory = sqlite3.Row
        c = db.cursor()
        error = None

        # (Redundant) check for uesrname and password entries
        if not form.username.data:
            error = "Username is required."
        elif not form.password.data:
            error = "Password is required."
        elif c.execute('SELECT id FROM Users WHERE username = ?',
                       (form.email.data, )).fetchone() is not None:
            error = 'User {} already exists.  Please try again with a different username, or log in.'.format(
                form.username.data)

        if error is None:
            c.execute("""INSERT INTO Users (
            'username', 
            'password', 
            'email', 
            'fName', 
            'lName', 
            'streetAddress', 
            'city', 
            'state', 
            'postCode') 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                      (form.username.data,
                       form.password.data,
                       form.email.data,
                       form.fName.data,
                       form.lName.data,
                       form.streetAddress.data,
                       form.city.data,
                       form.state.data,
                       form.postCode.data))
            db.commit()
            print(
                f"Signup: account created for {form.username.data}, with User id {c.lastrowid}")
            flash(f'Account created for {form.email.data}!', 'success')
            session['user_num'] = c.lastrowid
            return redirect(url_for('account'))
        flash(error, 'warning')
    return render_template('signup.html', form=form)


@app.route('/wishlist')
@login_required
def wishlist():
    db = get_db()
    db.row_factory = sqlite3.Row

    # Select user based on username, using generic for now
    c = db.cursor()
    # c.execute("SELECT id FROM Users WHERE username = ?", (session["user_num"],))

    # Fetch the user's id
    # userID = c.fetchall()[0]["id"]

    # Using the user's id, select their wishlists
    c.execute("SELECT * FROM Wishlists WHERE userId = ?",
              (session["user_num"],))

    wishlists = [row["id"] for row in c.fetchall()]

    # Build IN query string
    values = ""
    for wish in wishlists:
        values += str(wish) + ", "

    values = values[:-2]

    # Select book names per wishlist
    c.execute(
        "SELECT wishlistId, Books.title FROM WishlistsBooks w INNER JOIN Books ON w.bookId = Books.id WHERE wishlistId IN (?)",
        (values,))
    for row in c.fetchall():
        print([i for i in row])
    # Map wishlists to books for user
    c.execute(
        "SELECT wishlistId, Books.title FROM WishlistsBooks w INNER JOIN Books ON w.bookId = Books.id WHERE wishlistId IN (?)",
        (values,))
    wishBooks = {}
    for row in c.fetchall():
        if row[0] in wishBooks:
            wishBooks[row[0]].append(row[1])
        else:
            wishBooks[row[0]] = [row[1]]

    db.close()

    data = {}
    data["table_content"] = wishBooks
    data["headers"] = "Wishlists"
    return render_template('user/wishlist.html', data=data)


@app.route('/addToWishlist', methods=['GET'])
@login_required
def addToWish():
    db = get_db()
    db.row_factory = sqlite3.Row

    data = req.args.get("isbn")
    if data == "":
        return redirect('/wishlist')

    c = db.cursor()
    c.execute("SELECT * FROM Books WHERE ISBN = ?", (data,))
    bookId = c.fetchall()[0]['id']

    c.execute("INSERT INTO WishlistsBooks (wishlistId, bookId) VALUES (?, ?)",
              (req.args.get("wishlist"), bookId))
    db.commit()
    db.close()

    return redirect('/wishlist')


@app.route('/removeFromWishlist', methods=['GET'])
@login_required
def removeWish():
    db = get_db()
    db.row_factory = sqlite3.Row

    c = db.cursor()

    wishID = req.args.get("wishlistRem")
    bookID = req.args.get("bookRem")
    print(wishID, bookID)
    c.execute("DELETE FROM WishlistsBooks WHERE wishlistId = ? AND bookId = (SELECT id FROM Books WHERE title = ?)",
              (wishID, bookID))
    db.commit()
    db.close()

    return redirect('/wishlist')


@app.route('/account', methods=['GET', 'POST'])
@login_required
def account():
    bsdb = get_bsdb()
    # Check against request to change user settings
    if req.get_json() and req.get_json()['request'] == 'changeUserSettings':
        print("Account: request received for changeUserSettings")
        username = req.get_json()['username']
        # Check that the username isn't changing or is available

        if (username == bsdb.get_account_settings(session["user_num"])["username"]
                or bsdb.username_available(username)):
            success = bsdb.change_account_information(
                session['user_num'], req.get_json())
            if success == True:
                flash("Account information updated.", "success")
                print("Account: returning new account info:")
                account_settings = bsdb.get_account_settings(
                    session["user_num"])
                for key in account_settings.keys():
                    print(f"\t {key}: {account_settings[key]}")
                account_settings = bsdb.get_account_settings(
                    session["user_num"])
                bsdb.close()

                return render_template("user/user-home.html", account_settings=account_settings);

            else:
                flash("Error updating your information. Try again?", "warning")
                account_settings = bsdb.get_account_settings(
                    session["user_num"])
                bsdb.close()

                return render_template("user/user-home.html",
                                       account_settings = account_settings)

        else:
            account_settings = bsdb.get_account_settings(session["user_num"])
            flash("Username is already taken", "warning")

            return render_template("user/user-home.html",
                               account_settings = account_settings)


    # Check against request to change password
    if req.get_json() and req.get_json()['request'] == 'changePassword':
        print(
            f"Account: request received for changePassword for user {session['user_num']}")
        if not bsdb.check_password(session["user_num"], req.get_json()['oldPassword']):
            flash("Original password not correct")
            print(
                f"Account: Incorrect password entered for {session['user_num']}.")
            return {"passwordMismatch": True}

        success = bsdb.change_password(session["user_num"], req.get_json())
        if success == True:
            flash("Account password updated.", 'success')
            print(f"Account: Password updated for user {session['user_num']}.")
            account_settings = bsdb.get_account_settings(session["user_num"])
            return render_template("user/user-home.html", account_settings=account_settings)
        

    # Default behavior (for loading page)
    account_settings = bsdb.get_account_settings(session["user_num"])
    return render_template('user/user-home.html', account_settings=account_settings)


@app.route('/_add-book', methods=['POST'])
@login_required
def add_book():
    bsdb = get_bsdb()
    if req.get_json().get('request') == 'add':
        isbn = req.get_json()["isbn"]
        copyquality = req.get_json()["quality"]
        user_num = session["user_num"]
        bsdb.user_add_book_by_isbn(isbn, user_num, copyquality)
        rows = bsdb.get_listed_books(user_num)
        copyqualities = bsdb.get_book_qualities()

        # Build the data to be passed to Jinja
        headers = ["Title", "Author", "Quality", "ISBN"]
        table_content = [[row[header] for header in headers] for row in rows]
        data = {"headers": headers,
                "rows": table_content,
                "caption": "",
                "copyqualities": copyqualities}

        return render_template('user/my-books.html', data=data)



@app.route('/removeFromUserLibrary', methods=['GET'])
@login_required
def removeBook():
    db = get_db()
    db.row_factory = sqlite3.Row

    c = db.cursor()

    bookID = req.args.get("bookRem")
    print(bookID)
    c.execute("DELETE FROM UserBooks WHERE id = ?",
              (bookID,))
    db.commit()
    db.close()

    return redirect('/my-books')


@app.route('/my-books')
@login_required
def my_books():
    bsdb = get_bsdb()
    # Get the data of books currently listed
    rows = bsdb.get_listed_books(session['user_num'])
    copyqualities = bsdb.get_book_qualities()

    # Build the data to be passed to Jinja
    headers = ["Title", "Author", "Quality", "ISBN", "ID"]
    table_content = [[row[header] for header in headers] for row in rows]
    data = {"headers": headers,
            "rows": table_content,
            "caption": "",
            "copyqualities": copyqualities
            }

    return render_template('user/my-books.html', data=data)


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('home'))


@app.route('/demo-users')
def demo_users():
    db = get_db()
    # This allows us to access values by column name later on
    db.row_factory = sqlite3.Row
    """
    Step 1: run the SQL query
    Avoid Python's string operations when putting together SQL queries 
    Instead use '?' as a placeholder for each parameter then pass a tuple of parameters as the second argument
    """
    c = db.cursor()
    c.execute("SELECT * FROM Users WHERE city != ?", ("Nashville",))
    """
    Step 2: fetch the results from the SQL query.
    You can treat the cursor as an iterator or call .fetchall() to get a list of all matching rows
    
    Since we set the row factory above, we can access values by index (row[0]) or 
    by column name, case insensitively (row["uSErNAmE"])
    
    Accessing values by column name is useful if we move around columns later on
    """
    rows = c.fetchall()
    table_content = [[row["username"], row["fname"], row["lname"]]
                     for row in rows]
    # Don't forget to close the connection when done with the SQL
    db.close()
    """
    Step 3: pass the data to a jinja template to be rendered
    Here I passed the info as a list of lists,
    and used a loop in the jinja template to create the table
    """
    data = {}
    data["table_content"] = table_content
    data["headers"] = ["Username", "First Name", "Last Name"]
    return render_template("demos/demo-users.html", data=data)


@app.route('/reset-db')
def reset_db():
    """
    A "secret" route for resetting database specs and content.
    """
    with app.app_context():
        db = get_db()
        with app.open_resource('DatabaseSpecs/database-definition-queries.sql',
                               mode='r') as f:
            db.cursor().executescript(f.read())
        db.commit()
    return "Database reset :)"


if __name__ == '__main__':
    """
    `host` keyword arg added by Ben to make it work on his server.  It seems to 
    work the same on his local machine.  Maybe others can test too?
    """
    app.run(host='0.0.0.0', debug=True)

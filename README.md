# Lost & Found Platform

A simple backend for a campus lost-and-found board. Students can sign up, log in, and post about items they've lost or found.

## Built with

- **Django** — the web framework
- **Django REST Framework (DRF)** — for building the JSON API
- **PostgreSQL** — the database
- **django-environ** — loads settings (secret key, DB credentials) from a `.env` file instead of hardcoding them

## Apps folders we used

- `accounts` app — a custom User model that logs in with **phone number & Password**.
- `items` app — the `Post` model (a lost or found item) and its APIs: create, list, update, delete.

**Note on auth:** this project keeps auth intentionally simple for now. `/login/` just checks the phone + password and returns the user's `id` — there's no token. The app is trusted to send the user `id` back when creating a post.

## Running it from scratch

You'll need Python 3 and PostgreSQL installed and running.

```bash
# i. Get the code
git clone https://github.com/faysalf/academic-lost-and-found.git
cd academic-lost-and-found/lost_and_found

# ii. Set up a virtual environment and install dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# iii. Configure environment variables
cp .env.example .env
# then open .env and fill in a secret key + your local DB credentials

# iv. Create the database (if it doesn't exist yet)
createdb lost_found_db

# v. Set up the database tables
python manage.py makemigrations
python manage.py migrate

# vi. Run it
python manage.py runserver
```

The API is now live at `http://127.0.0.1:8000/`.

## API quick reference

| Method | Endpoint | What it does |
|---|---|---|
| POST | `/api/auth/signup/` | Create an account (phone, name, address, password) |
| POST | `/api/auth/login/` | Log in with phone + password, get back your user id |
| GET | `/api/posts/` | List all posts (add `?type=Lost` or `?type=Found` to filter) |
| POST | `/api/posts/` | Create a new post |
| GET | `/api/posts/<id>/` | View a single post |
| PATCH | `/api/posts/<id>/` | Update a post, e.g. `{"is_owner_given": true}` |
| DELETE | `/api/posts/<id>/` | Delete a post |

Every day after the first setup, we only need:

```bash
cd academic-lost-and-found/lost_and_found
source venv/bin/activate
python manage.py runserver

run on the same IP:
venv/bin/python manage.py runserver 0.0.0.0:8000
```

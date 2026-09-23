# How `GET /api/posts/<id>/` Works

This document explains how the API returns one lost-and-found post.

## Example request

```text
GET /api/posts/5/
```

The number `5` is the ID of the post we want to see.

## Step 1: Django matches the URL

In `lost_and_found/items/urls.py`, this line defines the URL:

```python
path('posts/<int:pk>/', PostDetailView.as_view(), name='post-detail')
```

The URL contains three important parts:

- `posts/` is the fixed part of the URL.
- `<int:pk>` means Django expects a whole number here.
- `pk` is the name Django gives to that number. It means primary key, which is the database ID.

For this request:

```text
/api/posts/5/
```

Django stores `5` as `pk`.

The `/api/` part comes from `lost_and_found/config/urls.py`:

```python
path('api/', include('items.urls'))
```

Django combines `/api/` with `posts/<int:pk>/` to create:

```text
/api/posts/5/
```

## Step 2: Django calls `PostDetailView`

The URL connects to this class in `lost_and_found/items/views.py`:

```python
class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
```

`RetrieveUpdateDestroyAPIView` is a built-in Django REST Framework class. It already knows how to handle these requests:

- `GET` retrieves and displays one post.
- `PATCH` updates one post.
- `DELETE` removes one post.

Because this class already provides the `GET` behavior, we do not need to write a separate `get()` function.

## Step 3: The view searches the database

The view tells Django which database objects it can search:

```python
queryset = Post.objects.all()
```

When the request is `/api/posts/5/`, Django REST Framework uses the `pk` value from the URL. Internally, it does something similar to:

```python
post = Post.objects.get(pk=5)
```

This means: find the `Post` whose ID is `5`.

If a post with ID `5` exists, the view continues. If it does not exist, the API returns a `404 Not Found` response.

## Step 4: The serializer prepares the response

The view specifies which serializer to use:

```python
serializer_class = PostSerializer
```

`PostSerializer` is defined in `lost_and_found/items/serializers.py`. It converts the Python `Post` object into data that can be sent as JSON.

The serializer includes fields such as:

```python
fields = (
    'id',
    'item_name',
    'description',
    'type',
    'is_owner_given',
    'user',
    'user_name',
    'created_at',
)
```

For example, a database post can be returned like this:

```json
{
  "id": 5,
  "item_name": "Black wallet",
  "description": "Found near the library",
  "type": "Found",
  "is_owner_given": false,
  "user": 2,
  "user_name": "Alex",
  "created_at": "2026-09-23T12:30:00Z"
}
```

## The complete flow

```text
GET /api/posts/5/
        |
        v
Django reads pk = 5 from the URL
        |
        v
PostDetailView searches for Post with ID 5
        |
        v
PostSerializer converts the post to JSON
        |
        v
The API returns the post details
```

## Other operations on the same URL

The same view also supports updating and deleting the post:

```text
PATCH  /api/posts/5/  -> update post 5
DELETE /api/posts/5/  -> delete post 5
```

For example, this request updates whether the owner has received the item:

```http
PATCH /api/posts/5/
```

```json
{
  "is_owner_given": true
}
```

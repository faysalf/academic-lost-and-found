from django.urls import path

from .views import PostListCreateView

app_name = 'items'

urlpatterns = [
    path('posts/', PostListCreateView.as_view(), name='post-list-create'),
]

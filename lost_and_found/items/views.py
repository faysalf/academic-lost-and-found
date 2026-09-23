from rest_framework import generics, permissions

from .models import Post
from .serializers import PostSerializer


class PostListCreateView(generics.ListCreateAPIView):
    """
    GET  /api/posts/            -> list all posts (Lost and Found), newest first
    GET  /api/posts/?type=Lost  -> list only Lost posts
    GET  /api/posts/?type=Found -> list only Found posts
    POST /api/posts/            -> create a new post
         body: {"item_name", "description", "type", "is_owner_given"?, "user"}
    """
    serializer_class = PostSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = Post.objects.select_related('user').all()
        post_type = self.request.query_params.get('type')
        if post_type:
            queryset = queryset.filter(type__iexact=post_type)
        return queryset


class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/posts/<id>/ -> view one post
    PATCH  /api/posts/<id>/ -> update one post, e.g. {"is_owner_given": true}
    DELETE /api/posts/<id>/ -> delete one post
    """
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.AllowAny]

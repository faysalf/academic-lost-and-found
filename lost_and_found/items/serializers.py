from rest_framework import serializers

from .models import Post


class PostSerializer(serializers.ModelSerializer):
    # No token-based auth is in use, so the client tells us who's
    # posting by passing the user's id (the one returned by /login/).
    user_name = serializers.CharField(source='user.name', read_only=True)

    class Meta:
        model = Post
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
        read_only_fields = ('id', 'created_at')

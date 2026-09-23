from django.contrib import admin

from .models import Post


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ('item_name', 'type', 'is_owner_given', 'user', 'created_at')
    list_filter = ('type', 'is_owner_given')
    search_fields = ('item_name', 'description', 'user__phone', 'user__name')

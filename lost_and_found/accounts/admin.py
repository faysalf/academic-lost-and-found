from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


class UserAdmin(BaseUserAdmin):
    ordering = ('phone',)
    list_display = ('phone', 'name', 'is_staff', 'is_active')
    search_fields = ('phone', 'name')
    fieldsets = (
        (None, {'fields': ('phone', 'password')}),
        ('Personal info', {'fields': ('name', 'address')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone', 'name', 'address', 'password1', 'password2'),
        }),
    )
    readonly_fields = ('date_joined',)
    filter_horizontal = ('groups', 'user_permissions')


admin.site.register(User, UserAdmin)

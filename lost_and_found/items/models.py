from django.conf import settings
from django.db import models


class Post(models.Model):
    LOST = 'Lost'
    FOUND = 'Found'
    TYPE_CHOICES = [
        (LOST, 'Lost'),
        (FOUND, 'Found'),
    ]

    item_name = models.CharField(max_length=150)
    description = models.TextField()
    type = models.CharField(max_length=5, choices=TYPE_CHOICES)
    is_owner_given = models.BooleanField(default=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='posts',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.type}] {self.item_name}'

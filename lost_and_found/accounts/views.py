from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import LoginSerializer, SignUpSerializer


class SignUpView(generics.CreateAPIView):
    """
    POST /api/auth/signup/
    Registers a new user with phone, name, address, password, password2.
    """
    serializer_class = SignUpSerializer
    permission_classes = [permissions.AllowAny]


class LoginView(APIView):
    """
    POST /api/auth/login/
    Body: {"phone": "...", "password": "..."}

    No token is issued. On success this simply confirms the credentials
    and returns the user's id, which the client attaches to later
    requests (e.g. as the "created_by"/user id on a post) to identify
    who is acting.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = LoginSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        return Response(
            {
                'id': user.id,
                'phone': user.phone,
                'name': user.name,
            },
            status=status.HTTP_200_OK,
        )

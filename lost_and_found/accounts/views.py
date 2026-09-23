from django.contrib.auth import authenticate
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import LoginSerializer


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            first_error = next(iter(serializer.errors.values()))[0]
            return Response(
                {'isSuccess': False, 'error': str(first_error), 'data': None},
                status=status.HTTP_400_BAD_REQUEST,
            )

        phone = serializer.validated_data['phone']
        password = serializer.validated_data['password']
        user = authenticate(request, phone=phone, password=password)

        if user is None:
            return Response(
                {'isSuccess': False, 'error': 'Invalid phone or password', 'data': None},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        refresh = RefreshToken.for_user(user)
        return Response(
            {
                'isSuccess': True,
                'error': None,
                'data': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                    'user': {
                        'id': user.id,
                        'phone': user.phone,
                        'address': user.address,
                    },
                },
            },
            status=status.HTTP_200_OK,
        )

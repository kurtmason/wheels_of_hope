from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import LandingPageView

router = DefaultRouter()

urlpatterns = [
    # Landing page
    path('', LandingPageView.as_view(), name='landing'),
    
    # API routes
    path('api/', include(router.urls)),
]

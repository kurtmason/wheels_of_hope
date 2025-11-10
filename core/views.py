from django.views.generic import ListView, DetailView, TemplateView
from rest_framework import viewsets
from .models import Donation
from .serializers import DonationSerializer


class LandingPageView(TemplateView):
    template_name = 'core/landing.html'

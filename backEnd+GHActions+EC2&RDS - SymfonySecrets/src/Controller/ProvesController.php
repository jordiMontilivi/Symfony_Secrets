<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class ProvesController extends AbstractController
{
    #[Route('/proves', name: 'app_proves')]
    public function index(): Response
    {
        return $this->render('proves/index.html.twig', [
            'controller_name' => 'ProvesController',
        ]);
    }
}

# Sistema Web de Citas Médicas - Clínica Sanna (AWS)
Repositorio de Infraestructura como Código (IaC) utilizando Terraform para automatizar el despliegue de los recursos en la nube.

## Integrantes - Grupo 06
* Chafloque Young Alexandra Ximena
* Murillo Pérez, José 
* Quevedo Alayo, Tatiana Antonella
* Vera Tacanga, Fabricio Sebastian
* Salazar Aguilar, Sebastian Jose

## Contexto del Proyecto
En la actualidad, las clínicas gestionan las citas mediante llamadas telefónicas o canales presenciales, generando colas, demoras y duplicidad de horarios. Además, la alta cantidad de solicitudes satura los canales de atención convencionales.

**Propuesta de Solución:**
Desarrollo de la plataforma web "SannaCitas", que permite a los pacientes consultar disponibilidad, seleccionar horarios en tiempo real y agendar citas. Toda la infraestructura se soporta en Amazon Web Services (AWS) para mantener el sistema rápido, seguro y disponible.

**Métricas y Requisitos Técnicos:**
* **Usuarios registrados:** Aprox. 4,000 pacientes.
* **Concurrencia:** 300 a 400 usuarios en condiciones normales, con picos estimados de hasta 800 usuarios simultáneos.
* **Alta Disponibilidad:** Tiempo máximo de inactividad de 5 minutos y backups automáticos configurados en la nube.

## Actualización de Arquitectura
Atendiendo al feedback de la exposición de arquitectura, se ha iniciado la codificación de la infraestructura asíncrona. Mediante Terraform, se está provisionando una cola **Amazon SQS** y un tema **Amazon SNS** para desacoplar el sistema de notificaciones, evitando bloqueos en los contenedores principales y mejorando la tolerancia a fallos del sistema.

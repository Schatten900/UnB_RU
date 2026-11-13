# Projeto Rails

## Agendamento das notificações FastPass

O cron deve ser instalado no host que executa a aplicação, com o ambiente e o
acesso ao banco configurados:

```
cd projeto-rails
RAILS_ENV=production bundle exec whenever --update-crontab projeto-rails
```

A agenda chama `NotificarFastPassJob` a cada minuto. Para removê-la:

```
bundle exec whenever --clear-crontab projeto-rails
```

O serviço `cron` do host precisa estar ativo. Para outro ambiente, substitua
`production` pelo valor correspondente de `RAILS_ENV`.

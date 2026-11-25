import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/atividade.dart';
import '../utils/formato.dart';
import '../viewmodels/atividades_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'atividade_form_view.dart';

class AtividadesView extends StatelessWidget {
  const AtividadesView({super.key});

  Future<void> _abrirFormulario(
    BuildContext context, [
    Atividade? atividade,
  ]) async {
    final vm = context.read<AtividadesViewModel>();
    final mensagens = ScaffoldMessenger.of(context);

    final preenchida = await Navigator.of(context).push<Atividade>(
      MaterialPageRoute(
        builder: (_) => AtividadeFormView(atividade: atividade),
      ),
    );
    if (preenchida == null) return;

    final ok = await vm.salvar(preenchida);
    mensagens.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Atividade salva.' : 'Não foi possível salvar a atividade.',
        ),
      ),
    );
  }

  Future<void> _confirmarRemocao(
    BuildContext context,
    Atividade atividade,
  ) async {
    final vm = context.read<AtividadesViewModel>();
    final mensagens = ScaffoldMessenger.of(context);

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Excluir atividade?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('botaoConfirmarExclusao'),
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    final ok = await vm.remover(atividade.id!);
    mensagens.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Atividade excluída.' : 'Não foi possível excluir a atividade.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AtividadesViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas atividades'),
        actions: [
          IconButton(
            key: const Key('botaoSair'),
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().sair(),
          ),
        ],
      ),
      body: switch (vm.estado) {
        EstadoLista.carregando =>
          const Center(child: CircularProgressIndicator()),
        EstadoLista.vazio => const _Aviso(
            icone: Icons.hiking,
            texto: 'Nenhuma atividade registrada ainda.',
            detalhe: 'Toque em + para registrar a primeira.',
          ),
        EstadoLista.erro => _Aviso(
            icone: Icons.cloud_off,
            texto: vm.mensagemErro ?? 'Algo deu errado.',
            acao: FilledButton.icon(
              key: const Key('botaoTentarNovamente'),
              onPressed: vm.tentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        EstadoLista.sucesso => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${vm.atividades.length} atividade(s) · '
                  '${formatarDistancia(vm.totalKm)} no total',
                  key: const Key('resumoLista'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: vm.atividades.length,
                  itemBuilder: (context, indice) {
                    final atividade = vm.atividades[indice];
                    return _ItemAtividade(
                      atividade: atividade,
                      aoEditar: () => _abrirFormulario(context, atividade),
                      aoExcluir: () => _confirmarRemocao(context, atividade),
                    );
                  },
                ),
              ),
            ],
          ),
      },
      floatingActionButton: FloatingActionButton(
        key: const Key('botaoNova'),
        tooltip: 'Nova atividade',
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ItemAtividade extends StatelessWidget {
  const _ItemAtividade({
    required this.atividade,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final Atividade atividade;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final clima = atividade.temperatura == null
        ? 'sem clima registrado'
        : '${atividade.local ?? 'Local'}: '
            '${formatarTemperatura(atividade.temperatura!)}, '
            '${atividade.condicao ?? ''}';

    return ListTile(
      leading: const Icon(Icons.directions_walk),
      title: Text(
        '${atividade.tipo} · ${formatarDistancia(atividade.distanciaKm)} · '
        '${atividade.duracaoMin} min',
      ),
      subtitle: Text('${formatarData(atividade.data)}\n$clima'),
      isThreeLine: true,
      onTap: aoEditar,
      trailing: IconButton(
        tooltip: 'Excluir',
        icon: const Icon(Icons.delete_outline),
        onPressed: aoExcluir,
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icone,
    required this.texto,
    this.detalhe,
    this.acao,
  });

  final IconData icone;
  final String texto;
  final String? detalhe;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: tema.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium,
            ),
            if (detalhe != null) ...[
              const SizedBox(height: 4),
              Text(detalhe!, textAlign: TextAlign.center),
            ],
            if (acao != null) ...[const SizedBox(height: 16), acao!],
          ],
        ),
      ),
    );
  }
}

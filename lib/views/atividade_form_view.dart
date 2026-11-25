import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/atividade.dart';
import '../repositories/clima_repository.dart';
import '../services/localizacao_service.dart';
import '../utils/formato.dart';
import '../viewmodels/clima_viewmodel.dart';

/// Formulário de criação e edição. Devolve a [Atividade] preenchida
/// via `Navigator.pop`; quem salva é a tela de lista, pelo ViewModel.
class AtividadeFormView extends StatefulWidget {
  const AtividadeFormView({super.key, this.atividade});

  final Atividade? atividade;

  @override
  State<AtividadeFormView> createState() => _AtividadeFormViewState();
}

class _AtividadeFormViewState extends State<AtividadeFormView> {
  final _formKey = GlobalKey<FormState>();
  final _distancia = TextEditingController();
  final _duracao = TextEditingController();
  final _cidade = TextEditingController();
  late String _tipo;
  late final ClimaViewModel _clima;

  @override
  void initState() {
    super.initState();
    final atual = widget.atividade;
    _tipo = atual?.tipo ?? Atividade.tipos.first;
    if (atual != null) {
      _distancia.text = atual.distanciaKm.toString().replaceAll('.', ',');
      _duracao.text = atual.duracaoMin.toString();
    }
    _clima = ClimaViewModel(
      context.read<ClimaRepository>(),
      context.read<LocalizacaoService>(),
    );
  }

  @override
  void dispose() {
    _distancia.dispose();
    _duracao.dispose();
    _cidade.dispose();
    _clima.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final atual = widget.atividade;
    final clima = _clima.resultado?.clima;

    Navigator.of(context).pop(
      Atividade(
        id: atual?.id,
        tipo: _tipo,
        distanciaKm: Atividade.lerDistancia(_distancia.text)!,
        duracaoMin: int.parse(_duracao.text.trim()),
        data: atual?.data ?? DateTime.now(),
        local: clima?.local ?? atual?.local,
        temperatura: clima?.temperatura ?? atual?.temperatura,
        condicao: clima?.descricao ?? atual?.condicao,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.atividade != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar atividade' : 'Nova atividade'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: [
                    for (final tipo in Atividade.tipos)
                      ButtonSegment(value: tipo, label: Text(tipo)),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (selecao) =>
                      setState(() => _tipo = selecao.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('campoDistancia'),
                  controller: _distancia,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Distância (km)',
                    border: OutlineInputBorder(),
                  ),
                  validator: Atividade.validarDistancia,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('campoDuracao'),
                  controller: _duracao,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duração (min)',
                    border: OutlineInputBorder(),
                  ),
                  validator: Atividade.validarDuracao,
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: _clima,
                  builder: (context, _) => _secaoClima(context),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('botaoSalvar'),
                  onPressed: _salvar,
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _secaoClima(BuildContext context) {
    final tema = Theme.of(context);
    final resultado = _clima.resultado;
    final anterior = widget.atividade;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Clima do local (opcional)', style: tema.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'A localização aproximada é usada só para consultar o clima. '
          'As coordenadas não são salvas.',
          style: tema.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('botaoLocalizacao'),
          onPressed: _clima.carregando ? null : _clima.usarLocalizacao,
          icon: const Icon(Icons.my_location),
          label: const Text('Usar minha localização'),
        ),
        if (!_clima.campoCidade)
          TextButton(
            key: const Key('botaoDigitarCidade'),
            onPressed: _clima.mostrarCampoCidade,
            child: const Text('Prefiro digitar a cidade'),
          ),
        if (_clima.campoCidade) ...[
          const SizedBox(height: 8),
          TextField(
            key: const Key('campoCidade'),
            controller: _cidade,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Cidade',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('botaoBuscarClima'),
            onPressed: _clima.carregando
                ? null
                : () => _clima.buscarPorCidade(_cidade.text),
            child: const Text('Buscar clima'),
          ),
        ],
        if (_clima.carregando)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        if (_clima.mensagem != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_clima.mensagem!, key: const Key('mensagemClima')),
          ),
        if (resultado != null)
          Card(
            key: const Key('cartaoClima'),
            margin: const EdgeInsets.only(top: 12),
            child: ListTile(
              leading: Icon(
                resultado.origem == OrigemClima.cache
                    ? Icons.cloud_off
                    : Icons.cloud_outlined,
              ),
              title: Text(
                '${resultado.clima.local}: '
                '${formatarTemperatura(resultado.clima.temperatura)}, '
                '${resultado.clima.descricao}',
              ),
              subtitle: Text(
                resultado.origem == OrigemClima.cache
                    ? 'Sem conexão: dado salvo em '
                        '${formatarData(resultado.clima.obtidoEm)}'
                    : 'Atualizado agora',
              ),
            ),
          )
        else if (anterior != null && anterior.temperatura != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Clima registrado: ${anterior.local ?? 'Local'}, '
              '${formatarTemperatura(anterior.temperatura!)}, '
              '${anterior.condicao ?? ''}',
            ),
          ),
      ],
    );
  }
}

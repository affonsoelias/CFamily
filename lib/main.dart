import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(FamiliaGastosApp());

class FamiliaGastosApp extends StatefulWidget {
  @override
  _FamiliaGastosAppState createState() => _FamiliaGastosAppState();
}

class _FamiliaGastosAppState extends State<FamiliaGastosApp> {
  ThemeMode _temaAtual = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _carregarTemaSalvo();
  }

  Future<void> _carregarTemaSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final temaSalvo = prefs.getString('tema') ?? 'light';
    setState(() {
      _temaAtual = temaSalvo == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _salvarTema(ThemeMode tema) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tema', tema == ThemeMode.dark ? 'dark' : 'light');
  }

  void alternarTema() {
    setState(() {
      _temaAtual = _temaAtual == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      _salvarTema(_temaAtual);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastos da Família',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _temaAtual,
      debugShowCheckedModeBanner: false,
      home: GastosPage(onToggleTheme: alternarTema, temaAtual: _temaAtual),
    );
  }
}

class Membro {
  String nome;
  double renda;

  Membro({required this.nome, required this.renda});
}

class GastosPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode temaAtual;

  const GastosPage({required this.onToggleTheme, required this.temaAtual});

  @override
  _GastosPageState createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  int numeroMembros = 1;
  int duracaoGasMeses = 1;
  List<Membro> membros = [Membro(nome: '', renda: 0.0)];
  List<TextEditingController> nomeControllers = [TextEditingController()];
  List<TextEditingController> rendaControllers = [TextEditingController()];

  final energiaController = TextEditingController();
  final aguaController = TextEditingController();
  final gasValorController = TextEditingController();
  final alimentacaoController = TextEditingController();
  final transporteController = TextEditingController();
  final aluguelController = TextEditingController();
  final medicamentosController = TextEditingController();

  double totalSalarios = 0.0;
  double totalGastos = 0.0;
  double saldoFinal = 0.0;
  double rendaPerCapita = 0.0;
  double gastoMensalGas = 0.0;

  @override
  void initState() {
    super.initState();
    for (var c in [
      energiaController,
      aguaController,
      gasValorController,
      alimentacaoController,
      transporteController,
      aluguelController,
      medicamentosController
    ]) {
      c.addListener(calcularResultados);
    }
  }

  void calcularResultados() {
    setState(() {
      totalSalarios = membros.fold(0.0, (s, m) => s + m.renda);
      double gasValor = double.tryParse(gasValorController.text) ?? 0.0;
      gastoMensalGas = duracaoGasMeses > 0 ? gasValor / duracaoGasMeses : gasValor;
      totalGastos = [
        energiaController,
        aguaController,
        alimentacaoController,
        transporteController,
        aluguelController,
        medicamentosController
      ].fold(gastoMensalGas, (s, c) => s + (double.tryParse(c.text) ?? 0.0));
      saldoFinal = totalSalarios - totalGastos;
      rendaPerCapita = numeroMembros > 0 ? totalSalarios / numeroMembros : 0.0;
    });
  }

  void limparCampos() {
    setState(() {
      numeroMembros = 1;
      duracaoGasMeses = 1;
      membros = [Membro(nome: '', renda: 0.0)];
      for (var c in nomeControllers) c.dispose();
      for (var c in rendaControllers) c.dispose();
      nomeControllers = [TextEditingController()];
      rendaControllers = [TextEditingController()];
      energiaController.clear();
      aguaController.clear();
      gasValorController.clear();
      alimentacaoController.clear();
      transporteController.clear();
      aluguelController.clear();
      medicamentosController.clear();
      totalSalarios = 0.0;
      totalGastos = 0.0;
      saldoFinal = 0.0;
      rendaPerCapita = 0.0;
      gastoMensalGas = 0.0;
    });
  }

  @override
  void dispose() {
    for (var c in nomeControllers) c.dispose();
    for (var c in rendaControllers) c.dispose();
    energiaController.dispose();
    aguaController.dispose();
    gasValorController.dispose();
    alimentacaoController.dispose();
    transporteController.dispose();
    aluguelController.dispose();
    medicamentosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gastos da Família'),
        actions: [
          IconButton(
            icon: Icon(widget.temaAtual == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Alternar Tema',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Número de membros:'),
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      if (numeroMembros > 1) {
                        setState(() {
                          numeroMembros--;
                          membros.removeLast();
                          nomeControllers.removeLast().dispose();
                          rendaControllers.removeLast().dispose();
                          calcularResultados();
                        });
                      }
                    },
                  ),
                  Text('$numeroMembros'),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        numeroMembros++;
                        membros.add(Membro(nome: '', renda: 0.0));
                        nomeControllers.add(TextEditingController());
                        rendaControllers.add(TextEditingController());
                        calcularResultados();
                      });
                    },
                  ),
                ],
              ),
              ...membros.asMap().entries.map((entry) {
                int i = entry.key;
                Membro m = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membro ${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextField(
                      controller: nomeControllers[i],
                      decoration: InputDecoration(labelText: 'Nome'),
                      onChanged: (val) => m.nome = val,
                    ),
                    TextField(
                      controller: rendaControllers[i],
                      decoration: InputDecoration(labelText: 'Renda (R\$)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (val) {
                        m.renda = double.tryParse(val) ?? 0.0;
                        calcularResultados();
                      },
                    ),
                    Divider(),
                  ],
                );
              }),
              Text('--- Gastos Mensais ---'),
              buildGastoField('Energia elétrica', energiaController),
              buildGastoField('Água', aguaController),
              TextField(
                decoration: InputDecoration(labelText: 'Valor do gás (R\$)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                controller: gasValorController,
              ),
              Row(
                children: [
                  Text('Duração do gás (meses):'),
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      if (duracaoGasMeses > 1) {
                        setState(() {
                          duracaoGasMeses--;
                          calcularResultados();
                        });
                      }
                    },
                  ),
                  Text('$duracaoGasMeses'),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        duracaoGasMeses++;
                        calcularResultados();
                      });
                    },
                  ),
                ],
              ),
              buildGastoField('Alimentação', alimentacaoController),
              buildGastoField('Transporte', transporteController),
              buildGastoField('Aluguel', aluguelController),
              buildGastoField('Medicamentos', medicamentosController),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: limparCampos,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Limpar'),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '--- Resultado ---',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              buildResultadoLinha('Total de Renda', totalSalarios),
              buildResultadoLinha('Total de Gastos', totalGastos),
              buildResultadoLinha('Saldo Final', saldoFinal),
              buildResultadoLinha('Renda Per Capita', rendaPerCapita),
              buildResultadoLinha('Gasto Mensal com Gás', gastoMensalGas),
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Autor: Affonso Elias Ferreira Jr',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGastoField(String label, TextEditingController controller) {
    return TextField(
      decoration: InputDecoration(labelText: '$label (R\$)'),
      keyboardType: TextInputType.number,
      controller: controller,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    );
  }

  Widget buildResultadoLinha(String titulo, double valor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? theme.colorScheme.surfaceVariant
        : theme.colorScheme.primary.withOpacity(0.05);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
          Text('R\$ ${valor.toStringAsFixed(2)}', style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}

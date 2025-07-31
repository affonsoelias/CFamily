import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

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
  String cpf;
  double renda;

  Membro({required this.nome, this.cpf = '', required this.renda});
}

class CPFInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    var newText = '';

    if (text.length > 11) {
      return oldValue;
    }

    if (text.length > 9) {
      newText =
          '${text.substring(0, 3)}.${text.substring(3, 6)}.${text.substring(6, 9)}-${text.substring(9, 11)}';
    } else if (text.length > 6) {
      newText =
          '${text.substring(0, 3)}.${text.substring(3, 6)}.${text.substring(6, text.length)}';
    } else if (text.length > 3) {
      newText = '${text.substring(0, 3)}.${text.substring(3, text.length)}';
    } else {
      newText = text;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
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
  List<Membro> membros = [Membro(nome: '', cpf: '', renda: 0.0)];
  List<TextEditingController> nomeControllers = [TextEditingController()];
  List<TextEditingController> cpfControllers = [TextEditingController()];
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
    _addListenersToControllers();
  }

  void _addListenersToControllers() {
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
    for (var i = 0; i < rendaControllers.length; i++) {
      rendaControllers[i].addListener(calcularResultados);
    }
  }

  void _removeListenersFromControllers() {
    for (var c in [
      energiaController,
      aguaController,
      gasValorController,
      alimentacaoController,
      transporteController,
      aluguelController,
      medicamentosController
    ]) {
      c.removeListener(calcularResultados);
    }
    for (var c in rendaControllers) {
      c.removeListener(calcularResultados);
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
      _removeListenersFromControllers(); // Remove listeners antes de limpar e descartar

      numeroMembros = 1;
      duracaoGasMeses = 1;

      for (var c in nomeControllers) c.dispose();
      for (var c in cpfControllers) c.dispose();
      for (var c in rendaControllers) c.dispose();

      membros = [Membro(nome: '', cpf: '', renda: 0.0)];
      nomeControllers = [TextEditingController()];
      cpfControllers = [TextEditingController()];
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

      _addListenersToControllers(); // Adiciona listeners novamente para os novos controladores
    });
  }

  Future<void> salvarDados() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operação de salvar cancelada.')),
        );
        return;
      }

      final DateTime now = DateTime.now();
      final String formattedDate = DateFormat('dd-MM-yyyy_HH-mm-ss').format(now);

      String rfNome = nomeControllers[0].text.isEmpty ? "RF" : nomeControllers[0].text;
      String rfCpfNumeros = cpfControllers[0].text.replaceAll(RegExp(r'\D'), '');

      String fileName = '${rfNome.replaceAll(' ', '_')}_${rfCpfNumeros}.txt';
      File file = File('$selectedDirectory/$fileName');

      StringBuffer content = StringBuffer();
      content.writeln('Dados Salvos em: $formattedDate');
      content.writeln('--- Membros da Família ---');
      for (int i = 0; i < numeroMembros; i++) {
        String memberTitle = (i == 0) ? 'RF' : 'Membro ${i + 1}';
        content.writeln('$memberTitle:');
        content.writeln('  Nome: ${nomeControllers[i].text}');
        content.writeln('  CPF: ${cpfControllers[i].text}');
        content.writeln('  Renda: R\$ ${double.tryParse(rendaControllers[i].text)?.toStringAsFixed(2) ?? '0.00'}');
      }

      content.writeln('\n--- Gastos Mensais ---');
      content.writeln('Energia elétrica: R\$ ${double.tryParse(energiaController.text)?.toStringAsFixed(2) ?? '0.00'}');
      content.writeln('Água: R\$ ${double.tryParse(aguaController.text)?.toStringAsFixed(2) ?? '0.00'}');
      content.writeln('Valor do gás: R\$ ${double.tryParse(gasValorController.text)?.toStringAsFixed(2) ?? '0.00'}');
      content.writeln('Duração do gás (meses): $duracaoGasMeses');
      content.writeln('Alimentação: R\$ ${double.tryParse(alimentacaoController.text)?.toStringAsFixed(2) ?? '0.00'}');
      content.writeln('Transporte: R\$ ${double.tryParse(transporteController.text)?.toStringAsFixed(2) ?? '0.00'}');
      content.writeln('Aluguel: R\$ ${double.tryParse(aluguelController.text)?.toStringAsFixed(2) ?? '0.00'}');
      content.writeln('Medicamentos: R\$ ${double.tryParse(medicamentosController.text)?.toStringAsFixed(2) ?? '0.00'}');

      content.writeln('\n--- Resultados ---');
      content.writeln('Total de Renda: R\$ ${totalSalarios.toStringAsFixed(2)}');
      content.writeln('Total de Gastos: R\$ ${totalGastos.toStringAsFixed(2)}');
      content.writeln('Saldo Final: R\$ ${saldoFinal.toStringAsFixed(2)}');
      content.writeln('Renda Per Capita: R\$ ${rendaPerCapita.toStringAsFixed(2)}');
      content.writeln('Gasto Mensal com Gás: R\$ ${gastoMensalGas.toStringAsFixed(2)}');

      await file.writeAsString(content.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dados salvos em: ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar dados: $e')),
      );
    }
  }

  Future<void> carregarDados() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operação de carregar cancelada.')),
        );
        return;
      }

      File file = File(result.files.single.path!);
      String content = await file.readAsString();

      // Limpa os campos antes de carregar novos dados
      limparCampos();

      // Implementar a lógica de parsing para o conteúdo do TXT
      List<String> lines = content.split('\n');
      int currentLineIndex = 0;

      // Ignora a linha de data e a linha de separação
      if (lines[currentLineIndex].startsWith('Dados Salvos em:')) currentLineIndex++;
      if (lines[currentLineIndex].contains('--- Membros da Família ---')) currentLineIndex++;

      // Carrega membros
      List<Membro> loadedMembros = [];
      List<TextEditingController> newNomeControllers = [];
      List<TextEditingController> newCpfControllers = [];
      List<TextEditingController> newRendaControllers = [];

      while (currentLineIndex < lines.length && lines[currentLineIndex].startsWith('Membro') || lines[currentLineIndex].startsWith('RF:')) {
        String memberLine = lines[currentLineIndex++]; // RF: ou Membro X:
        String nome = lines[currentLineIndex++].replaceAll('  Nome: ', '');
        String cpf = lines[currentLineIndex++].replaceAll('  CPF: ', '');
        String rendaStr = lines[currentLineIndex++].replaceAll('  Renda: R\$ ', '');
        double renda = double.tryParse(rendaStr) ?? 0.0;
        loadedMembros.add(Membro(nome: nome, cpf: cpf, renda: renda));

        newNomeControllers.add(TextEditingController(text: nome));
        newCpfControllers.add(TextEditingController(text: cpf));
        newRendaControllers.add(TextEditingController(text: rendaStr));

        if (currentLineIndex < lines.length && lines[currentLineIndex].trim().isEmpty) {
          currentLineIndex++; // Ignora a linha em branco entre os membros
        }
      }

      setState(() {
        numeroMembros = loadedMembros.length;
        membros = loadedMembros;

        // Descartar os controladores antigos antes de atribuir os novos
        for (var c in nomeControllers) c.dispose();
        for (var c in cpfControllers) c.dispose();
        for (var c in rendaControllers) c.dispose();

        nomeControllers = newNomeControllers;
        cpfControllers = newCpfControllers;
        rendaControllers = newRendaControllers;

        // Adicionar listeners para os novos controladores de renda
        for (var c in rendaControllers) {
          c.addListener(calcularResultados);
        }
      });

      // Pula a linha em branco e a linha de separação dos gastos
      while (currentLineIndex < lines.length && lines[currentLineIndex].trim().isEmpty) {
        currentLineIndex++;
      }
      if (lines[currentLineIndex].contains('--- Gastos Mensais ---')) currentLineIndex++;

      // Carrega gastos mensais
      Map<String, TextEditingController> gastoControllers = {
        'Energia elétrica: R\$': energiaController,
        'Água: R\$': aguaController,
        'Valor do gás: R\$': gasValorController,
        'Alimentação: R\$': alimentacaoController,
        'Transporte: R\$': transporteController,
        'Aluguel: R\$': aluguelController,
        'Medicamentos: R\$': medicamentosController,
      };

      while (currentLineIndex < lines.length && !lines[currentLineIndex].contains('--- Resultados ---') && !lines[currentLineIndex].contains('--- Membros da Família ---')) {
        String line = lines[currentLineIndex].trim();
        if (line.isEmpty) {
          currentLineIndex++;
          continue;
        }

        if (line.startsWith('Duração do gás (meses):')) {
          duracaoGasMeses = int.tryParse(line.replaceAll('Duração do gás (meses): ', '')) ?? 1;
        } else {
          for (var entry in gastoControllers.entries) {
            if (line.startsWith(entry.key)) {
              String value = line.replaceAll(entry.key, '');
              entry.value.text = value;
              break;
            }
          }
        }
        currentLineIndex++;
      }
      
      calcularResultados(); // Recalcula após carregar todos os dados

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dados carregados com sucesso de: ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e\nCertifique-se de que o arquivo está no formato correto.')),
      );
      print(e); // Para depuração
    }
  }

  @override
  void dispose() {
    _removeListenersFromControllers();
    for (var c in nomeControllers) c.dispose();
    for (var c in cpfControllers) c.dispose();
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
                          cpfControllers.removeLast().dispose();
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
                        membros.add(Membro(nome: '', cpf: '', renda: 0.0));
                        var newNomeController = TextEditingController();
                        var newCpfController = TextEditingController();
                        var newRendaController = TextEditingController();

                        nomeControllers.add(newNomeController);
                        cpfControllers.add(newCpfController);
                        rendaControllers.add(newRendaController);

                        newRendaController.addListener(calcularResultados);
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
                      i == 0 ? 'RF' : 'Membro ${i + 1}',
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
                      controller: cpfControllers[i],
                      decoration: InputDecoration(labelText: 'CPF'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CPFInputFormatter(),
                        LengthLimitingTextInputFormatter(14), // 11 dígitos + 3 pontos + 1 traço
                      ],
                      onChanged: (val) => m.cpf = val,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: carregarDados, // Novo botão Carregar
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: Text('Carregar'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: salvarDados,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text('Salvar'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: limparCampos,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('Limpar'),
                  ),
                ],
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
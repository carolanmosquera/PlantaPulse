import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/core/theme/app_theme.dart';

void main() {
  Future<void> mostrar(WidgetTester tester, bool oscuro) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        darkTheme: AppTheme.oscuro,
        themeMode: oscuro ? ThemeMode.dark : ThemeMode.light,
        home: Builder(
          builder: (context) => PantallaBase(
            titulo: 'Componentes',
            cuerpo: ListView(
              children: [
                TarjetaBlanca(
                  child: Text(
                    'Contenido',
                    style: AppText.cuerpo.segunTema(context),
                  ),
                ),
                const FilaOpcion(icono: Icons.settings, titulo: 'Opción'),
                const CampoTexto(label: 'Nombre', hint: 'Tu nombre'),
                BotonAncho(texto: 'Acción', onTap: () {}),
                BotonAncho(
                  texto: 'Alternativa',
                  estilo: EstiloBoton.borde,
                  onTap: () {},
                ),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        const AlertDialog(title: Text('Confirmación')),
                  ),
                  child: const Text('Abrir diálogo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color superficie(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(TarjetaBlanca),
            matching: find.byType(Container),
          )
          .first,
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  testWidgets(
    'el tema claro conserva la paleta y el oscuro mantiene contraste',
    (tester) async {
      await mostrar(tester, false);
      expect(superficie(tester), Colors.white);
      expect(
        tester.widget<Text>(find.text('Contenido')).style!.color,
        AppColors.texto,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.fillColor,
        Colors.white,
      );
      await mostrar(tester, true);
      final fondo = superficie(tester);
      final texto = tester.widget<Text>(find.text('Contenido')).style!.color!;
      expect(fondo.computeLuminance(), lessThan(0.1));
      expect(
        (texto.computeLuminance() + 0.05) / (fondo.computeLuminance() + 0.05),
        greaterThan(7),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.fillColor,
        fondo,
      );
      final titulo = tester.widget<Text>(find.text('Opción')).style!.color!;
      expect(
        (titulo.computeLuminance() + 0.05) / (fondo.computeLuminance() + 0.05),
        greaterThan(4.5),
      );
      // Los botones de marca mantienen su fondo y texto blanco.
      final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(boton.style!.backgroundColor!.resolve({}), AppColors.azul);
      expect(boton.style!.foregroundColor!.resolve({}), Colors.white);
      expect(find.byType(ColorFiltered), findsNothing);
    },
  );

  testWidgets('diálogos y controles Material heredan el modo oscuro', (
    tester,
  ) async {
    await mostrar(tester, true);
    await tester.tap(find.text('Abrir diálogo'));
    await tester.pumpAndSettle();
    final contexto = tester.element(find.text('Confirmación'));
    expect(Theme.of(contexto).brightness, Brightness.dark);
    expect(
      Theme.of(contexto).colorScheme.surface.computeLuminance(),
      lessThan(0.1),
    );
  });
}

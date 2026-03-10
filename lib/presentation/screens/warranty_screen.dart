import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Warranty Screen
// Гарантийный талон KM Jaqin | Kassenov Motors
// ============================================================

class WarrantyScreen extends StatelessWidget {
  const WarrantyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: KmScreenHeader(
                title: 'Гарантия',
                subtitle: 'Действительна до 2031 г.',
                showBack: true,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverToBoxAdapter(
                child: _WarrantyContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantyContent extends StatelessWidget {
  const _WarrantyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Шапка документа ──────────────────────────────
        _DocHeader(),
        const SizedBox(height: 24),

        // ── 1. Общие положения ────────────────────────────
        const _Section(
          number: '1',
          title: 'Общие положения',
          child: _BodyText(
            'Компания Kassenov Motors (далее — «Производитель») '
            'гарантирует высокое качество и надежность автомобиля KM Jaqin '
            'и предоставляет официальные гарантийные обязательства при '
            'соблюдении владельцем условий эксплуатации, обслуживания и '
            'хранения, установленных настоящим гарантийным талоном.\n\n'
            'Гарантия распространяется на все автомобили KM Jaqin, '
            'реализованные через официальную дилерскую сеть Kassenov Motors '
            'на территории Республики Казахстан, государств-членов ЕАЭС, '
            'а также стран официального присутствия бренда.',
          ),
        ),

        // ── 2. Сроки гарантии ─────────────────────────────
        const _Section(
          number: '2',
          title: 'Срок гарантии',
          child: _WarrantyTable(
            headers: ['Тип гарантии', 'Срок', 'Пробег'],
            rows: [
              ['Базовая гарантия', '7 лет', '150 000 км'],
              ['Лакокрасочное покрытие', '5 лет', 'Без ограничений'],
              ['Сквозная коррозия кузова', '10 лет', 'Без ограничений'],
              ['Высоковольтная батарея', '8 лет', '120 000 км'],
            ],
          ),
        ),

        // ── 3. Что покрывает ──────────────────────────────
        const _Section(
          number: '3',
          title: 'Что покрывает гарантия',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(
                'Гарантия распространяется на любые дефекты материалов '
                'и производственные недостатки, возникшие по вине '
                'Производителя при нормальной эксплуатации автомобиля.',
              ),
              SizedBox(height: 12),
              _CoverageTable(
                rows: [
                  ['⚙️', 'Двигатель и системы', 'Включая турбокомпрессор'],
                  ['🔄', 'Трансмиссия', 'Авто и механические КПП'],
                  ['❄️', 'Охлаждение и отопление', 'Включая климат-контроль'],
                  ['⚡', 'Электрооборудование', 'Все приборы и датчики'],
                  ['🚗', 'Рулевое управление', 'Гидро- и электроусилитель'],
                  ['🛑', 'Тормозная система', 'Кроме колодок и дисков'],
                  ['💨', 'Подвеска', 'Амортизаторы, рычаги, опоры'],
                  ['🛡️', 'Системы безопасности', 'Подушки, ремни, ABS, ESP'],
                  ['🔋', 'Гибридные компоненты', 'Электродвигатели, инверторы'],
                ],
              ),
            ],
          ),
        ),

        // ── 4. Что не покрывает ───────────────────────────
        _Section(
          number: '4',
          title: 'Что не покрывает гарантия',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SubTitle('4.1. Расходные материалы'),
              const SizedBox(height: 8),
              ...[
                'Тормозные колодки и диски',
                'Щётки стеклоочистителей',
                'Лампы освещения (кроме заводского брака)',
                'Аккумулятор 12V (кроме брака в первые 6 мес.)',
                'Шины и колёсные диски',
                'Ремни и фильтры',
                'Свечи зажигания',
                'Жидкости и масла',
              ].map((e) => _BulletItem(e)),
              const SizedBox(height: 12),
              const _SubTitle('4.2. Повреждения вследствие'),
              const SizedBox(height: 8),
              ...[
                'ДТП',
                'Нарушения правил эксплуатации',
                'Использования неоригинальных запчастей',
                'Изменений конструкции без согласования',
                'Естественного износа деталей',
                'Внешних факторов (гравий, реагенты, химия)',
                'Форс-мажора (пожар, наводнение, стихия)',
              ].map((e) => _BulletItem(e)),
              const SizedBox(height: 12),
              const _SubTitle('4.3. Регулировочные работы'),
              const SizedBox(height: 8),
              ...[
                'Регулировка фар',
                'Балансировка колёс',
                'Развал-схождение',
                'Очистка и промывка систем',
                'Заправка кондиционера',
              ].map((e) => _BulletItem(e)),
            ],
          ),
        ),

        // ── 5. Условия сохранения ─────────────────────────
        _Section(
          number: '5',
          title: 'Условия сохранения гарантии',
          child: Column(
            children: [
              ...[
                'Прохождение ТО строго у официальных дилеров Kassenov Motors',
                'Использование оригинальных запчастей и жидкостей',
                'Соблюдение правил обкатки (первые 3 000 км)',
                'Своевременное информирование дилера о неисправностях',
                'Сохранение заводских пломб и идентификационных номеров',
                'Эксплуатация на официальном рынке присутствия KM Motors',
              ].map((e) => _CheckItem(e)),
              const SizedBox(height: 10),
              const _WarningBox(
                'Гарантия аннулируется при выявлении фактов эксплуатации '
                'автомобиля с нарушением правил, установленных производителем.',
              ),
            ],
          ),
        ),

        // ── 6. Порядок обслуживания ───────────────────────
        _Section(
          number: '6',
          title: 'Порядок гарантийного обслуживания',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SubTitle('6.1. При обнаружении неисправности'),
              const SizedBox(height: 8),
              ...[
                'Обратиться в любой официальный сервисный центр Kassenov Motors',
                'Предоставить автомобиль, гарантийный талон и сервисную книжку',
                'Описать характер неисправности',
              ].map((e) => _NumberedItem(e, [
                    'Обратиться в любой официальный сервисный центр Kassenov Motors',
                    'Предоставить автомобиль, гарантийный талон и сервисную книжку',
                    'Описать характер неисправности',
                  ].indexOf(e) + 1)),
              const SizedBox(height: 12),
              const _SubTitle('6.2. Сроки рассмотрения'),
              const SizedBox(height: 8),
              const _TimelineItem('Диагностика (бесплатно)', 'до 2 часов'),
              const _TimelineItem('Решение о гарантийном ремонте', 'до 24 часов'),
              const _TimelineItem('Сложные случаи (с заводом)', 'до 5 раб. дней'),
              const SizedBox(height: 12),
              const _SubTitle('6.3. Сроки выполнения ремонта'),
              const SizedBox(height: 8),
              const _TimelineItem('Запчасти на складе', 'до 3 раб. дней'),
              const _TimelineItem('Запчасти под заказ', 'до 21 раб. дня'),
              const SizedBox(height: 12),
              const _InfoBox(
                'При ремонте более 14 рабочих дней дилер предоставляет '
                'подменный автомобиль (при наличии в автопарке).',
              ),
            ],
          ),
        ),

        // ── 7. Передача гарантии ──────────────────────────
        _Section(
          number: '7',
          title: 'Передача гарантии новому владельцу',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BodyText(
                'Гарантия является передаваемой. При продаже автомобиля '
                'гарантийные обязательства сохраняются при условии:',
              ),
              const SizedBox(height: 8),
              ...[
                'Уведомления дилера о смене собственника',
                'Внесения записи в сервисную книжку',
                'Отсутствия нарушений условий гарантии предыдущим владельцем',
              ].map((e) => _BulletItem(e)),
            ],
          ),
        ),

        // ── 8. Особые условия KM Jaqin ────────────────────
        _Section(
          number: '8',
          title: 'Особые условия KM Jaqin',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SubTitle('8.1. Гибридная версия'),
              const SizedBox(height: 8),
              ...[
                'Высоковольтная батарея обслуживается только у официальных дилеров',
                'Запрещена самостоятельная замена высоковольтных компонентов',
                'Специализированное ПО для диагностики',
              ].map((e) => _BulletItem(e)),
              const SizedBox(height: 12),
              const _SubTitle('8.2. Система полного привода (AWD)'),
              const SizedBox(height: 8),
              ...[
                'Прохождение ТО каждые 10 000 км',
                'Использование только рекомендованных масел в трансмиссии',
              ].map((e) => _BulletItem(e)),
              const SizedBox(height: 12),
              const _SubTitle('8.3. Панорамная крыша'),
              const SizedBox(height: 8),
              ...[
                'Чистка дренажных систем при каждом ТО',
                'Осторожное использование зимой (очистка от снега и наледи)',
              ].map((e) => _BulletItem(e)),
            ],
          ),
        ),

        // ── 9. Поддержка на дороге ────────────────────────
        const _Section(
          number: '9',
          title: 'Гарантийная поддержка на дороге',
          child: Column(
            children: [
              _ContactRow('📞', 'Горячая линия', '+7 (727) 333-44-55'),
              SizedBox(height: 8),
              _ContactRow('📱', 'Через KM Drive', 'Кнопка SOS'),
              SizedBox(height: 8),
              _ContactRow('🆘', 'Эвакуация до дилера', 'Бесплатно при гарантийном случае'),
            ],
          ),
        ),

        // ── 10. Расширенная гарантия ──────────────────────
        const _Section(
          number: '11',
          title: 'Расширенная гарантия (опционально)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(
                  'Владелец может приобрести пакет KM Extended Protection:'),
              SizedBox(height: 12),
              _WarrantyTable(
                headers: ['Пакет', 'Срок', 'Пробег'],
                rows: [
                  ['Standard', '+2 года', '+50 000 км'],
                  ['Premium', '+3 года', '+100 000 км'],
                  ['Full', '+5 лет', '+150 000 км'],
                ],
              ),
              SizedBox(height: 10),
              _BodyText(
                  'Приобретается до окончания базовой гарантии.'),
            ],
          ),
        ),

        // ── 12. Контакты ──────────────────────────────────
        const _Section(
          number: '12',
          title: 'Контакты и поддержка',
          child: Column(
            children: [
              _ContactRow('☎️', 'Центр поддержки', '+7 (727) 123-45-67'),
              SizedBox(height: 8),
              _ContactRow('✉️', 'Гарантийный отдел', 'warranty@km.kz'),
              SizedBox(height: 8),
              _ContactRow('💻', 'Тех. поддержка KM Drive', 'drive@km.kz'),
              SizedBox(height: 8),
              _ContactRow('🆘', 'Экстренная помощь', '+7 (727) 333-44-55'),
              SizedBox(height: 8),
              _ContactRow('📍', 'Центральный офис',
                  'г. Алматы, пр. Аль-Фараби, 150, БЦ «Nurly Tau»'),
            ],
          ),
        ),

        // ── Подвал документа ─────────────────────────────
        const SizedBox(height: 8),
        const _DocFooter(),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Компоненты
// ════════════════════════════════════════════════════════════

class _DocHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: KmColors.cardGradient,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.accentDim, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: KmColors.accentDim, width: 0.5),
                borderRadius: BorderRadius.circular(KmRadius.xs),
              ),
              child: const Text('KM',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: KmColors.accent,
                    letterSpacing: 3,
                  )),
            ),
            const SizedBox(width: 10),
            const Text('KASSENOV MOTORS',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 9,
                  letterSpacing: 2,
                  color: KmColors.textMuted,
                )),
          ]),
          const SizedBox(height: 14),
          const Text('ГАРАНТИЙНЫЙ ТАЛОН',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: KmColors.textPrimary,
                letterSpacing: 1,
              )),
          const SizedBox(height: 2),
          const Text('KM JAQIN',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                letterSpacing: 3,
                color: KmColors.accent,
              )),
          const SizedBox(height: 14),
          const KmDivider(),
          const SizedBox(height: 12),
          const Row(children: [
            _HeaderCell('VIN', 'KMXJQ200L2400523'),
            SizedBox(width: 20),
            _HeaderCell('НОМЕР', 'A523KM'),
            SizedBox(width: 20),
            _HeaderCell('ГОД', '2024'),
          ]),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 8,
              letterSpacing: 1.5,
              color: KmColors.textMuted,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KmColors.accent,
            )),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.title,
    required this.child,
  });

  final String number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: KmColors.overlayAccent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: KmColors.accentDim, width: 0.5),
              ),
              child: Center(
                child: Text(number,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: KmColors.accent,
                    )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: KmColors.textPrimary,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 20),
        const KmDivider(),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: KmTextStyles.bodySmall.copyWith(
          color: KmColors.textSecondary,
          height: 1.65,
        ));
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: KmColors.textPrimary,
          letterSpacing: 0.3,
        ));
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 4, height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: KmColors.accentDim,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.bodySmall
                    .copyWith(color: KmColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _NumberedItem extends StatelessWidget {
  const _NumberedItem(this.text, this.number);
  final String text;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18, height: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: KmColors.accentDim, width: 0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$number',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 9,
                      color: KmColors.accent,
                    )),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.bodySmall
                    .copyWith(color: KmColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: KmColors.success, size: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.bodySmall
                    .copyWith(color: KmColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: KmTextStyles.bodySmall
                    .copyWith(color: KmColors.textSecondary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: KmColors.surface3,
              borderRadius: BorderRadius.circular(KmRadius.xs),
              border: Border.all(color: KmColors.border, width: 0.5),
            ),
            child: Text(value,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: KmColors.accent,
                )),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(this.icon, this.label, this.value);
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: KmTextStyles.caption
                        .copyWith(color: KmColors.textMuted)),
                const SizedBox(height: 1),
                Text(value,
                    style: KmTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyTable extends StatelessWidget {
  const _WarrantyTable({required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: KmColors.surface3,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(KmRadius.md),
                topRight: Radius.circular(KmRadius.md),
              ),
            ),
            child: Row(
              children: headers.asMap().entries.map((e) => Expanded(
                flex: e.key == 0 ? 3 : 2,
                child: Text(e.value.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: KmColors.textMuted,
                    )),
              )).toList(),
            ),
          ),
          // Строки
          ...rows.asMap().entries.map((rowEntry) {
            final i = rowEntry.key;
            final row = rowEntry.value;
            return Column(
              children: [
                if (i > 0)
                  const Divider(
                      height: 0,
                      thickness: 0.5,
                      color: KmColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: row.asMap().entries.map((e) => Expanded(
                      flex: e.key == 0 ? 3 : 2,
                      child: Text(e.value,
                          style: KmTextStyles.bodySmall.copyWith(
                            color: e.key == 2
                                ? KmColors.accent
                                : KmColors.textPrimary,
                            fontWeight: e.key == 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    )).toList(),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _CoverageTable extends StatelessWidget {
  const _CoverageTable({required this.rows});
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return Column(
            children: [
              if (i > 0)
                const Divider(
                    height: 0, thickness: 0.5, color: KmColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(row[0], style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row[1],
                              style: KmTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500)),
                          Text(row[2],
                              style: KmTextStyles.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_rounded,
                        color: KmColors.success, size: 14),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0F5A8FE0),
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: const Color(0x335A8FE0), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.caption.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x14C8A96E),
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.accentDim, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.caption
                    .copyWith(color: KmColors.warning, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _DocFooter extends StatelessWidget {
  const _DocFooter();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('С уважением,',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: KmColors.textMuted,
              )),
          SizedBox(height: 4),
          Text('Команда Kassenov Motors',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: KmColors.accent,
                letterSpacing: 0.5,
              )),
          SizedBox(height: 8),
          Text(
            'KM Jaqin — ваша уверенность на дорогах на долгие годы.',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              color: KmColors.textMuted,
              letterSpacing: 0.3,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
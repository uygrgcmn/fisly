import 'package:fisly/features/expenses/domain/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptParser();

  test('extracts merchant, Turkish date, and labeled total', () {
    final parsed = parser.parse(
      'MİGROS TİCARET A.Ş.\n'
      'TARİH: 25.11.2026 14:32\n'
      'ARA TOPLAM: 1.200,00 TL\n'
      'GENEL TOPLAM: 1.234,56 TL',
    );

    expect(parsed.merchant, 'MİGROS TİCARET A.Ş.');
    expect(parsed.occurredAt, DateTime(2026, 11, 25));
    expect(parsed.totalMinorUnits, 123456);
  });

  test('prefers the labeled total over subtotal and later payment lines', () {
    final parsed = parser.parse(
      'MARKET\n'
      'ARA TOPLAM: 10,00 TL\n'
      'TOPLAM: 12,00 TL\n'
      'KART: 20,00 TL',
    );

    expect(parsed.totalMinorUnits, 1200);
  });

  test('supports year-first dates and decimal points', () {
    final parsed = parser.parse('Cafe\n2026-11-25\nTOPLAM 8.5 TL');

    expect(parsed.occurredAt, DateTime(2026, 11, 25));
    expect(parsed.totalMinorUnits, 850);
  });

  test('extracts total from a Market receipt with cash and change lines', () {
    final parsed = parser.parse(
      'ÖRNEK İŞLETME\n'
      'DEMİRCİKARA MAH. 1431 SOK. NO:12\n'
      'TARİH : 07.05.2019  SAAT : 12:30\n'
      'SATIŞ NO : 2\n'
      'KASİYER : AHMET\n'
      'ALINAN PARA 100,00\n'
      'PARA ÜSTÜ 9,80\n'
      'GENEL TOPLAM 90,20\n'
      'KDV FİŞİ DEĞİLDİR',
    );

    expect(parsed.merchant, 'ÖRNEK İŞLETME');
    expect(parsed.occurredAt, DateTime(2019, 5, 7));
    expect(parsed.totalMinorUnits, 9020);
  });

  test('matches a total label to amounts emitted later in OCR text', () {
    final parsed = parser.parse(
      'DEMİRCİKARA MAH. 1431 SOK. NO:12\n'
      '0242 311 41 21\n'
      'ANTALYA\n'
      'TARİH\n'
      'SATIŞ NO\n'
      'KASİYER\n'
      ': 07.05.2019\n'
      ':2\n'
      ':AHMET\n'
      '69236555 (1 ADET X 15,00)\n'
      'ÖRNEK ÜRÜN 1\n'
      '48640991 (1 ADET X 5,75)\n'
      'ÖRNEK ÜRÜN 2\n'
      'ÖRNEK İŞLETME\n'
      'ÖRNEK ÜRÜN 3\n'
      '8691573002575 (2 ADET X 12,00)\n'
      'ÖRNEK ÜRÜN 4\n'
      '8691728000108 (1 ADET X 19,95)\n'
      'ÖRNEK ÜRÜN 5\n'
      'SAAT : 12:30\n'
      'SATIŞ : NAKİT\n'
      '8693891805254 (3 ADET X 8,50)\n'
      'ALINAN PARA\n'
      'PARA ÜSTÜ\n'
      'GENEL TOPLAM\n'
      'KDV FİŞİ DEĞİLDİR\n'
      '15,00\n'
      '5,75\n'
      '24,00\n'
      '19,95\n'
      '25,50\n'
      '100,00\n'
      '9,80\n'
      '90,20',
    );

    expect(parsed.merchant, 'ÖRNEK İŞLETME');
    expect(parsed.totalMinorUnits, 9020);
  });

  test('returns null for invalid dates and non-total amounts', () {
    final parsed = parser.parse(
      'FİŞ NO: 123\n'
      'TARİH: 31.02.2026\n'
      'ARA TOPLAM: 10,00 TL\n'
      'KDV TOPLAM: 2,00 TL',
    );

    expect(parsed.merchant, isNull);
    expect(parsed.occurredAt, isNull);
    expect(parsed.totalMinorUnits, isNull);
  });
}

import 'class_scontrino.dart';

Map<String, dynamic> buildMgwsCheckoutPayload({
  required Scontrino scontrino,
  String? customerName,
  String? customerEmail,
  String? customerPhone,
}) {
  final saleItems = scontrino.righe
      .where((riga) => riga.tipoMovimento == TipoRigaCassa.vendita)
      .map(_serializeCheckoutLine)
      .toList();
  final returnItems = scontrino.righe
      .where((riga) => riga.tipoMovimento == TipoRigaCassa.reso)
      .map(_serializeCheckoutLine)
      .toList();
  final metadata = <Map<String, dynamic>>[
    {'key': '_punto_vendita', 'value': 'Cassa POS'},
    {'key': '_id_scontrino_locale', 'value': scontrino.id},
    {'key': '_data_operazione', 'value': scontrino.data.toIso8601String()},
    {
      'key': '_tipo_operazione_cassa',
      'value': scontrino.tipoOperazioneEffettiva.value,
    },
    {'key': '_totale_resi', 'value': scontrino.totaleResi.toStringAsFixed(2)},
    {'key': '_saldo_operazione', 'value': scontrino.totale.toStringAsFixed(2)},
  ];

  final payload = <String, dynamic>{
    'operation_type': scontrino.tipoOperazione.value,
    'effective_operation_type': scontrino.tipoOperazioneEffettiva.value,
    'payment_method': scontrino.metodoPagamento,
    'payment_method_title': _paymentMethodTitle(
      scontrino.metodoPagamento,
      isRefund: scontrino.totale < 0,
    ),
    'set_paid': scontrino.totale >= 0,
    'customer': {
      if (customerName != null && customerName.isNotEmpty)
        'first_name': customerName,
      if (customerEmail != null && customerEmail.isNotEmpty)
        'email': customerEmail,
      if (customerPhone != null && customerPhone.isNotEmpty)
        'phone': customerPhone,
    },
    'sale_items': saleItems,
    'return_items': returnItems,
    'totals': {
      'subtotale': scontrino.subtotale,
      'iva': scontrino.iva,
      'sconto': scontrino.sconto,
      'coupon_sconto': scontrino.couponSconto,
      'totale': scontrino.totale,
      'totale_vendite': scontrino.totaleVendite,
      'totale_resi': scontrino.totaleResi,
      'saldo_operazione': scontrino.saldoOperazione,
      'resto': scontrino.resto,
    },
    'meta_data': metadata,
  };

  if (scontrino.note != null && scontrino.note!.isNotEmpty) {
    payload['note'] = scontrino.note;
  }

  if (saleItems.isNotEmpty && returnItems.isNotEmpty) {
    metadata.add({
      'key': '_righe_reso',
      'value': returnItems
          .map(
            (item) =>
                '${item['sku']} x${item['quantity']} (€${item['subtotal']})',
          )
          .join(' | '),
    });
  }

  return payload;
}

String _paymentMethodTitle(String method, {required bool isRefund}) {
  switch (method) {
    case 'contanti':
      return isRefund ? 'Rimborso in Contanti' : 'Pagamento in Contanti';
    case 'carta':
      return isRefund ? 'Rimborso su Carta' : 'Carta di Credito';
    case 'bancomat':
      return isRefund ? 'Rimborso Bancomat/POS' : 'Bancomat/POS';
    default:
      return isRefund ? 'Rimborso' : 'Altro';
  }
}

Map<String, dynamic> _serializeCheckoutLine(RigaScontrino line) {
  return <String, dynamic>{
    if (line.prodotto.id != null) 'product_id': line.prodotto.id,
    if (line.variante != null) 'variation_id': line.variante!.id,
    'quantity': line.quantita,
    'sku': line.variante?.sku ?? line.prodotto.sku,
    'name': line.nomeCompleto,
    'unit_price': line.prezzoUnitario,
    'subtotal': line.subtotale,
    'movement_type': line.tipoMovimento.value,
  };
}

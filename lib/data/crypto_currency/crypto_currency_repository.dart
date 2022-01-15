import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:injectable/injectable.dart';

import '../../config.dart';
import '../../domain/core/api_exception.dart';
import '../../domain/core/logger/logger.dart';
import '../../domain/crypto_currency/crypto_currency.dart';
import '../../domain/crypto_currency/crypto_currency_repository.dart';
import '../utils/converters.dart';
import 'crypto_currency_cache.dart';

@LazySingleton(as: ICryptoCurrencyRepository)
class CryptoCurrencyRepository implements ICryptoCurrencyRepository {
  final Dio dio;
  final CryptoCurrencyCache cryptoCurrencyCache;
  final Logger logger;

  final _options = CacheOptions(
    // HiveCacheStore('crypto_currencies_request_store')
    store: MemCacheStore(),
    maxStale: const Duration(minutes: 15),
  );
  CryptoCurrencyRepository(this.dio, this.cryptoCurrencyCache, this.logger) {
    dio.interceptors.add(DioCacheInterceptor(options: _options));
  }

  /// first page is page = 1
  @override
  Future<List<CryptoCurrency>> getLatest(int page, int pageSize) async {
    try {
      // await Future.delayed(const Duration(seconds: 1));

      // return fakeCryptoCurrencies(pageSize);
      final response = await getFromCurrencyApi(
          '/cryptocurrency/listings/latest',
          queryParameters: {
            'limit': pageSize,
            'start': page,
          });
      final data = response.data['data'] as List;
      final latest = data
          .map((json) => cryptoCurrencyFromApiListingsLatest(json))
          .toList();
      // await cryptoCurrencyCache.cacheAll(latest);
      return latest;
    } on DioError catch (e) {
      final String? errorMessage = errorMessageFromApiError(e);
      logger.error(errorMessage);
      throw ApiException(errorMessage ?? 'Unknown error');
    } catch (e) {
      logger.error(e.toString());
      rethrow;
    }
  }

  // To see format in which the data is returned from the api, visit: https://coinmarketcap.com/api/documentation/v1/#operation/getV1CryptocurrencyListingsHistorical
  CryptoCurrency cryptoCurrencyFromApiListingsLatest(
      Map<String, dynamic> json) {
    final id = json['id'];
    return CryptoCurrency(
      currentPrice: json['quote']['USD']['price'],
      percentChange1h: json['quote']['USD']['percent_change_1h'],
      percentChange24h: json['quote']['USD']['percent_change_24h'],
      percentChange7d: json['quote']['USD']['percent_change_7d'],
      symbol: json['symbol'],
      iconUrl: 'https://s2.coinmarketcap.com/static/img/coins/64x64/$id.png',
      name: json['name'],
      currency: Currency.usd,
      priceLastUpdated: DateTime.parse(json['quote']['USD']['last_updated']),
      id: id,
    );
  }

  @override
  Future<List<CryptoCurrency>> getCryptoCurrenciesByIds(List<int> ids) async {
    // for (var element in (await cryptoCurrencyCache
    //     .getInTimespan(DateTime.now().subtract(const Duration(minutes: 10))))) {
    //   ids.remove(element.id);
    // }
    return await getCryptoCurrenciesBy(ids, "id");
  }

  @override
  Future<List<CryptoCurrency>> getCryptoCurrencyBySymbols(
      List<String> symbols) async {
    // for (var element in (await cryptoCurrencyCache
    //     .getInTimespan(DateTime.now().subtract(const Duration(minutes: 10))))) {
    //   symbols.remove(element.symbol);
    // }
    final result = await getCryptoCurrenciesBy(symbols, 'symbol');
    return result;
  }

  /// [what] indicates which query paramter should be used to query crypto currencies
  Future<List<CryptoCurrency>> getCryptoCurrenciesBy(
      List l, String what) async {
    try {
      if (l.isEmpty) {
        return List.empty();
      } // https://coinmarketcap.com/api/documentation/v1/#operation/getV1CryptocurrencyQuotesLatest
      final commaSeperated = convertListToCommaSeperatedStringListing(l);
      final response = await getFromCurrencyApi(
        '/cryptocurrency/quotes/latest',
        queryParameters: {what: commaSeperated},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final currencies = data.entries
          .map((entry) => cryptoCurrencyFromApiListingsLatest(entry.value))
          .toList();
      return currencies;
    } on DioError catch (e) {
      final String? errorMessage = errorMessageFromApiError(e);
      logger.warning(e.toString());
      // logger.warning(errorMessage);

      throw ApiException(errorMessage ?? e.toString());
    } catch (e) {
      logger.error(e.toString());
      rethrow;
    }
  }

  Future<Response> getFromCurrencyApi(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return dio.get(
      config.coinMarketCapApiUrl + path,
      options: Options(
        headers: {'X-CMC_PRO_API_KEY': config.coinMarketCapApiKey},
      ),
      queryParameters: queryParameters,
    );
  }

  String? errorMessageFromApiError(DioError e) {
    final String? errorMessage = e.response?.data['status']['error_message'];
    return errorMessage;
  }

  // final Cache<CryptoCurrency> cryptoCurrencyCache = Cache();

  // void cacheCurrency(CryptoCurrency cryptoCurrency) {}
}

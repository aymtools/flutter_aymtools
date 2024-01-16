extension ExpandoGetOrPut<T extends Object> on Expando<T> {
  T getOrPut(Object key, {required T Function() defaultValue}) {
    T? r = this[key];
    if (r == null) {
      r = defaultValue();
      this[key] = r;
    }
    return r;
  }

  void remove(Object key) => this[key] = null;
}

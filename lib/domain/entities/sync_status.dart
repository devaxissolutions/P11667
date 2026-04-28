enum SyncStatus {
  synced,    // All operations synced
  pending,   // Operations waiting to sync
  syncing,   // Currently syncing
  error,     // Some operations failed
}

/**
 * Helper to download files reliably in both sandboxed iframes and top-level windows.
 */
export async function downloadFile(url: string, filename: string): Promise<void> {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch file: ${response.statusText}`);
    }
    const blob = await response.blob();
    const blobUrl = window.URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.style.display = 'none';
    anchor.href = blobUrl;
    anchor.download = filename;
    document.body.appendChild(anchor);
    anchor.click();
    setTimeout(() => {
      document.body.removeChild(anchor);
      window.URL.revokeObjectURL(blobUrl);
    }, 200);
  } catch (error) {
    console.error('Blob download failed, falling back to direct navigation:', error);
    // Fallback: open absolute URL in new tab
    const absoluteUrl = new URL(url, window.location.href).href;
    window.open(absoluteUrl, '_blank');
  }
}

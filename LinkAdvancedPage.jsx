import React, { useState, useEffect } from 'react';
import axios from 'axios';
import {
  Box,
  Typography,
  TextField,
  Button,
  Card,
  CardContent,
  Paper,
  IconButton,
  Alert,
  CircularProgress,
  Grid,
  Container,
  Snackbar,
  Tab,
  Tabs,
  Switch,
  FormControlLabel,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Divider,
  Chip,
  Avatar,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions
} from '@mui/material';
import {
  ContentCopy as CopyIcon,
  Launch as LaunchIcon,
  Link as LinkIcon,
  Add as AddIcon,
  Notifications as NotificationsIcon,
  AccountCircle as AccountCircleIcon,
  QrCode as QrCodeIcon,
  CloudUpload as UploadIcon,
  Palette as PaletteIcon,
  Visibility as PreviewIcon,
  Settings as SettingsIcon,
  AutoAwesome as AIIcon
} from '@mui/icons-material';

const LinkAdvancedPage = () => {
  // Basic form states
  const [longUrl, setLongUrl] = useState('');
  const [title, setTitle] = useState('');
  const [customBackHalf, setCustomBackHalf] = useState('');
  const [domain] = useState('marketincer.com');
  
  // QR Code states
  const [enableQR, setEnableQR] = useState(false);
  const [qrColor, setQrColor] = useState('#882AFF');
  const [logoFile, setLogoFile] = useState(null);
  const [logoPreview, setLogoPreview] = useState(null);
  
  // UTM Parameters states
  const [enableUTM, setEnableUTM] = useState(false);
  const [utmSource, setUtmSource] = useState('');
  const [utmMedium, setUtmMedium] = useState('');
  const [utmCampaign, setUtmCampaign] = useState('');
  const [utmTerm, setUtmTerm] = useState('');
  const [utmContent, setUtmContent] = useState('');
  
  // UI states
  const [loading, setLoading] = useState(false);
  const [generatedUrl, setGeneratedUrl] = useState(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  const [previewDialog, setPreviewDialog] = useState(false);
  const [activeTab, setActiveTab] = useState(1);
  
  // AI Content Generation states
  const [postContent, setPostContent] = useState('');
  const [generatingContent, setGeneratingContent] = useState(false);
  const [showContentSection, setShowContentSection] = useState(false);

  // Color palette for QR codes
  const qrColors = [
    '#0b0b0b', // Black
    '#882AFF', // Vivid Violet
    '#091A48', // Navy Blue
    '#FF4444', // Red
    '#FF8800', // Orange
    '#00AA00', // Green
    '#0088FF', // Blue
    '#8800FF', // Purple
    '#FF0088'  // Pink
  ];

  // Generate preview URL with UTM parameters
  const generatePreviewUrl = () => {
    if (!longUrl) return '';
    
    let previewUrl = longUrl;
    const utmParams = [];
    
    if (enableUTM) {
      if (utmSource) utmParams.push(`utm_source=${encodeURIComponent(utmSource)}`);
      if (utmMedium) utmParams.push(`utm_medium=${encodeURIComponent(utmMedium)}`);
      if (utmCampaign) utmParams.push(`utm_campaign=${encodeURIComponent(utmCampaign)}`);
      if (utmTerm) utmParams.push(`utm_term=${encodeURIComponent(utmTerm)}`);
      if (utmContent) utmParams.push(`utm_content=${encodeURIComponent(utmContent)}`);
    }
    
    if (utmParams.length > 0) {
      const separator = longUrl.includes('?') ? '&' : '?';
      previewUrl = `${longUrl}${separator}${utmParams.join('&')}`;
    }
    
    return previewUrl;
  };

  // Generate short URL preview
  const getShortUrlPreview = () => {
    const backHalf = customBackHalf || 'abc123';
    return `${domain}/${backHalf}`;
  };

  // Handle logo upload
  const handleLogoUpload = (event) => {
    const file = event.target.files[0];
    if (file) {
      setLogoFile(file);
      const reader = new FileReader();
      reader.onload = (e) => {
        setLogoPreview(e.target.result);
      };
      reader.readAsDataURL(file);
    }
  };

  // Generate QR Code (mock implementation)
  const generateQRCode = () => {
    const url = getShortUrlPreview();
    // In a real implementation, you'd use a QR code library like qrcode
    // For now, we'll show a placeholder
    return `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(url)}&color=${qrColor.replace('#', '')}&bgcolor=FFFFFF`;
  };

  const handleCreateLink = async () => {
    if (!longUrl.trim()) {
      showSnackbar('Please enter a destination URL', 'warning');
      return;
    }

    setLoading(true);
    
    // Simulate API call
    setTimeout(() => {
      const finalUrl = generatePreviewUrl();
      setGeneratedUrl({
        short_url: getShortUrlPreview(),
        long_url: finalUrl,
        qr_code: enableQR ? generateQRCode() : null
      });
      setLoading(false);
      showSnackbar('Link created successfully!', 'success');
    }, 2000);
  };

  const handleCopyUrl = async (url) => {
    try {
      await navigator.clipboard.writeText(url);
      showSnackbar('URL copied to clipboard!', 'success');
    } catch (error) {
      showSnackbar('Failed to copy URL', 'error');
    }
  };

  const showSnackbar = (message, severity = 'success') => {
    setSnackbar({ open: true, message, severity });
  };

  const handleCloseSnackbar = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  // Generate with AI function
  const handleGenerateWithAI = async () => {
    setGeneratingContent(true);
    try {
      const token = localStorage.getItem("token");
      const response = await axios.post(
        "https://api.marketincer.com/api/v1/generate-content", // Replace with your actual endpoint
        {
          description: "generate note on social media"
        },
        {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json"
          }
        }
      );
      
      // Insert the generated content into the editor
      const generatedContent = response.data.content || response.data.message || response.data;
      setPostContent(generatedContent);
      
      showSnackbar("Content generated successfully!", "success");
    } catch (error) {
      console.error("Error generating content:", error);
      
      // For demo purposes, use the sample response you provided
      const sampleResponse = `Here's a well-structured note on social media:
---
### Note on Social Media
Definition:
Social media refers to digital platforms and applications that enable users to create, share, and interact with content, ideas, and information in virtual communities and networks.
---
Popular Platforms:
* Facebook: For social networking and community building.
* Instagram: For photo and video sharing.
* Twitter (X): For microblogging and real-time updates.
* LinkedIn: For professional networking.
* YouTube: For video sharing and streaming.
* WhatsApp & Telegram: For messaging and group communication.
---
Importance of Social Media:
1. Communication: Provides instant and global connectivity.
2. Information Sharing: Acts as a major source of news and knowledge.
3. Marketing & Branding: Businesses use social media for advertising and customer engagement.
4. Education & Awareness: Helps spread awareness about social, political, and environmental issues.
5. Entertainment: Offers a wide variety of content such as memes, videos, music, and more.
---
Positive Impacts:
* Strengthens relationships and communities.
* Promotes small businesses and entrepreneurship.
* Provides a platform for self-expression and creativity.
* Encourages social and cultural exchange.
---
Negative Impacts:
* Cyberbullying and online harassment.
* Spread of misinformation and fake news.
* Addiction leading to reduced productivity.
* Privacy concerns and data breaches.
---
Conclusion:
Social media is a powerful tool that can connect, educate, and entertain. However, responsible usage is essential to avoid its negative effects and ensure a safe online environment.
---
Would you like me to create this as a short handwritten-style note (suitable for study/revision) or as a detailed infographic-style note?`;
      
      setPostContent(sampleResponse);
      
      showSnackbar("Using sample content for demo", "info");
    } finally {
      setGeneratingContent(false);
    }
  };

  return (
    <Box sx={{ bgcolor: '#f5f5f5', minHeight: '100vh' }}>
      {/* Header */}

      <Container maxWidth="xl" sx={{ py: 4 }}>
        <Card sx={{ mb: 4, boxShadow: 4, borderRadius: 3 }}>
          <CardContent sx={{ p: 4 }}>
            {/* Tab Switcher */}
            <Box sx={{ mb: 4 }}>
            </Box>
            
            <Grid container spacing={4}>
              {/* Left Column - Form */}
              <Grid item xs={12} lg={8}>
                {/* Destination */}
                <Box sx={{ mb: 3 }}>
                  <Typography variant="h6" sx={{ mb: 1, color: '#091A48', fontWeight: 'bold' }}>
                    Destination
                  </Typography>
                  <TextField
                    fullWidth
                    placeholder="https://example.com/my-long-url"
                    value={longUrl}
                    onChange={(e) => setLongUrl(e.target.value)}
                    variant="outlined"
                    sx={{
                      '& .MuiOutlinedInput-root': {
                        borderRadius: 2,
                        '&:hover fieldset': {
                          borderColor: '#882AFF',
                        },
                        '&.Mui-focused fieldset': {
                          borderColor: '#882AFF',
                        }
                      }
                    }}
                    InputProps={{
                      startAdornment: <LinkIcon sx={{ mr: 1, color: '#882AFF' }} />
                    }}
                  />
                </Box>

                {/* Title */}
                <Box sx={{ mb: 3 }}>
                  <Typography variant="h6" sx={{ mb: 1, color: '#091A48', fontWeight: 'bold' }}>
                    Title (optional)
                  </Typography>
                  <TextField
                    fullWidth
                    placeholder="Enter a title for your link"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    variant="outlined"
                    sx={{
                      '& .MuiOutlinedInput-root': {
                        borderRadius: 2,
                        '&:hover fieldset': {
                          borderColor: '#882AFF',
                        },
                        '&.Mui-focused fieldset': {
                          borderColor: '#882AFF',
                        }
                      }
                    }}
                  />
                </Box>

                {/* Short Link */}
                <Box sx={{ mb: 3 }}>
                  <Typography variant="h6" sx={{ mb: 1, color: '#091A48', fontWeight: 'bold' }}>
                    Short link
                  </Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <FormControl sx={{ minWidth: 200 }}>
                      <InputLabel>Domain</InputLabel>
                      <Select
                        value={domain}
                        label="Domain"
                        disabled
                        sx={{
                          borderRadius: 2,
                          '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                            borderColor: '#882AFF',
                          }
                        }}
                      >
                        <MenuItem value="marketincer.com">marketincer.com</MenuItem>
                      </Select>
                    </FormControl>
                    <Typography variant="h6" sx={{ mx: 1 }}>/</Typography>
                    <TextField
                      fullWidth
                      placeholder="custom-back-half (optional)"
                      value={customBackHalf}
                      onChange={(e) => setCustomBackHalf(e.target.value)}
                      variant="outlined"
                      sx={{
                        '& .MuiOutlinedInput-root': {
                          borderRadius: 2,
                          '&:hover fieldset': {
                            borderColor: '#882AFF',
                          },
                          '&.Mui-focused fieldset': {
                            borderColor: '#882AFF',
                          }
                        }
                      }}
                    />
                  </Box>
                </Box>

                <Divider sx={{ my: 4 }} />

                {/* Ways to Share Section */}
                <Typography variant="h5" sx={{ mb: 3, color: '#091A48', fontWeight: 'bold' }}>
                  Ways to share
                </Typography>

                {/* QR Code Section */}
                <Card sx={{ mb: 3, bgcolor: '#f8f9ff', border: '1px solid #e0e7ff' }}>
                  <CardContent>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <QrCodeIcon sx={{ color: '#882AFF' }} />
                        <Typography variant="h6" sx={{ color: '#091A48', fontWeight: 'bold' }}>
                          QR Code
                        </Typography>
                      </Box>
                      <Switch
                        checked={enableQR}
                        onChange={(e) => setEnableQR(e.target.checked)}
                        sx={{
                          '& .MuiSwitch-switchBase.Mui-checked': {
                            color: '#882AFF',
                          },
                          '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                            backgroundColor: '#882AFF',
                          },
                        }}
                      />
                    </Box>

                    {enableQR && (
                      <Grid container spacing={3}>
                        <Grid item xs={12} md={6}>
                          <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 'bold' }}>
                            Code color
                          </Typography>
                          <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', mb: 3 }}>
                            {qrColors.map((color) => (
                              <IconButton
                                key={color}
                                onClick={() => setQrColor(color)}
                                sx={{
                                  width: 40,
                                  height: 40,
                                  bgcolor: color,
                                  border: qrColor === color ? '3px solid #882AFF' : '2px solid #ccc',
                                  '&:hover': {
                                    transform: 'scale(1.1)',
                                  }
                                }}
                              />
                            ))}
                          </Box>

                          <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 'bold' }}>
                            Logo
                          </Typography>
                          <Button
                            variant="outlined"
                            component="label"
                            startIcon={<UploadIcon />}
                            sx={{
                              borderColor: '#882AFF',
                              color: '#882AFF',
                              '&:hover': {
                                borderColor: '#091A48',
                                bgcolor: 'rgba(136, 42, 255, 0.04)',
                              }
                            }}
                          >
                            Choose logo
                            <input
                              type="file"
                              hidden
                              accept="image/*"
                              onChange={handleLogoUpload}
                            />
                          </Button>
                          {logoPreview && (
                            <Box sx={{ mt: 2 }}>
                              <img
                                src={logoPreview}
                                alt="Logo preview"
                                style={{ width: 60, height: 60, objectFit: 'contain', border: '1px solid #ccc', borderRadius: 4 }}
                              />
                            </Box>
                          )}
                        </Grid>
                        <Grid item xs={12} md={6}>
                          <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 'bold' }}>
                            Preview
                          </Typography>
                          <Box sx={{ 
                            p: 2, 
                            bgcolor: 'white', 
                            borderRadius: 2, 
                            border: '1px solid #e0e0e0',
                            display: 'flex',
                            justifyContent: 'center'
                          }}>
                            <img
                              src={generateQRCode()}
                              alt="QR Code Preview"
                              style={{ width: 150, height: 150 }}
                            />
                          </Box>
                          <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                            More customizations are available after creating
                          </Typography>
                        </Grid>
                      </Grid>
                    )}
                  </CardContent>
                </Card>

                <Divider sx={{ my: 4 }} />

                {/* UTM Parameters Section */}
                <Typography variant="h5" sx={{ mb: 3, color: '#091A48', fontWeight: 'bold' }}>
                  Advanced features
                </Typography>

                <Card sx={{ mb: 3, bgcolor: '#f8fff8', border: '1px solid #e0ffe0' }}>
                  <CardContent>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <SettingsIcon sx={{ color: '#882AFF' }} />
                        <Typography variant="h6" sx={{ color: '#091A48', fontWeight: 'bold' }}>
                          UTM parameters
                        </Typography>
                      </Box>
                      <Switch
                        checked={enableUTM}
                        onChange={(e) => setEnableUTM(e.target.checked)}
                        sx={{
                          '& .MuiSwitch-switchBase.Mui-checked': {
                            color: '#882AFF',
                          },
                          '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                            backgroundColor: '#882AFF',
                          },
                        }}
                      />
                    </Box>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                      Add UTMs to track web traffic in analytics tools
                    </Typography>

                    {enableUTM && (
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <TextField
                          fullWidth
                          label="Source"
                          placeholder="e.g., google, newsletter"
                          value={utmSource}
                          onChange={(e) => setUtmSource(e.target.value)}
                          variant="outlined"
                          size="small"
                          sx={{
                            '& .MuiOutlinedInput-root': {
                              '&:hover fieldset': {
                                borderColor: '#882AFF',
                              },
                              '&.Mui-focused fieldset': {
                                borderColor: '#882AFF',
                              }
                            }
                          }}
                        />
                        <TextField
                          fullWidth
                          label="Medium"
                          placeholder="e.g., cpc, email"
                          value={utmMedium}
                          onChange={(e) => setUtmMedium(e.target.value)}
                          variant="outlined"
                          size="small"
                          sx={{
                            '& .MuiOutlinedInput-root': {
                              '&:hover fieldset': {
                                borderColor: '#882AFF',
                              },
                              '&.Mui-focused fieldset': {
                                borderColor: '#882AFF',
                              }
                            }
                          }}
                        />
                        <TextField
                          fullWidth
                          label="Campaign"
                          placeholder="e.g., spring_sale"
                          value={utmCampaign}
                          onChange={(e) => setUtmCampaign(e.target.value)}
                          variant="outlined"
                          size="small"
                          sx={{
                            '& .MuiOutlinedInput-root': {
                              '&:hover fieldset': {
                                borderColor: '#882AFF',
                              },
                              '&.Mui-focused fieldset': {
                                borderColor: '#882AFF',
                              }
                            }
                          }}
                        />
                        <TextField
                          fullWidth
                          label="Term"
                          placeholder="e.g., running+shoes"
                          value={utmTerm}
                          onChange={(e) => setUtmTerm(e.target.value)}
                          variant="outlined"
                          size="small"
                          sx={{
                            '& .MuiOutlinedInput-root': {
                              '&:hover fieldset': {
                                borderColor: '#882AFF',
                              },
                              '&.Mui-focused fieldset': {
                                borderColor: '#882AFF',
                              }
                            }
                          }}
                        />
                        <TextField
                          fullWidth
                          label="Content"
                          placeholder="e.g., logolink, textlink"
                          value={utmContent}
                          onChange={(e) => setUtmContent(e.target.value)}
                          variant="outlined"
                          size="small"
                          sx={{
                            '& .MuiOutlinedInput-root': {
                              '&:hover fieldset': {
                                borderColor: '#882AFF',
                              },
                              '&.Mui-focused fieldset': {
                                borderColor: '#882AFF',
                              }
                            }
                          }}
                        />
                      </Box>
                    )}
                  </CardContent>
                </Card>

                {/* AI Content Generation Section */}
                <Card sx={{ mb: 3, bgcolor: '#fff8f0', border: '1px solid #ffe0b3' }}>
                  <CardContent>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <AIIcon sx={{ color: '#882AFF' }} />
                        <Typography variant="h6" sx={{ color: '#091A48', fontWeight: 'bold' }}>
                          AI Content Generation
                        </Typography>
                      </Box>
                      <Switch
                        checked={showContentSection}
                        onChange={(e) => setShowContentSection(e.target.checked)}
                        sx={{
                          '& .MuiSwitch-switchBase.Mui-checked': {
                            color: '#882AFF',
                          },
                          '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                            backgroundColor: '#882AFF',
                          }
                        }}
                      />
                    </Box>
                    
                    {showContentSection && (
                      <Box sx={{ mt: 3 }}>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                          Generate AI-powered social media content to accompany your shortened links.
                        </Typography>
                        
                        <Box sx={{ mb: 3 }}>
                          <Button
                            variant="contained"
                            onClick={handleGenerateWithAI}
                            disabled={generatingContent}
                            startIcon={generatingContent ? <CircularProgress size={20} /> : (
                              <Box sx={{ 
                                width: 24, 
                                height: 24, 
                                display: 'flex', 
                                alignItems: 'center', 
                                justifyContent: 'center',
                                borderRadius: '50%',
                                bgcolor: 'rgba(255,255,255,0.2)'
                              }}>
                                <img 
                                  src="/marketincer.jpg" 
                                  alt="Marketincer Logo" 
                                  style={{
                                    width: '100%',
                                    height: '100%',
                                    objectFit: 'contain',
                                    borderRadius: '50%'
                                  }}
                                />
                              </Box>
                            )}
                            sx={{
                              py: 1.5,
                              px: 3,
                              fontSize: '1rem',
                              fontWeight: 'bold',
                              background: 'linear-gradient(45deg, #882AFF 30%, #091A48 90%)',
                              '&:hover': {
                                background: 'linear-gradient(45deg, #7a26e6 30%, #082040 90%)',
                              },
                              '&:disabled': {
                                background: '#ccc',
                              }
                            }}
                          >
                            {generatingContent ? 'Generating...' : 'Generate with AI'}
                          </Button>
                        </Box>

                        {postContent && (
                          <Box sx={{ mt: 3 }}>
                            <Typography variant="subtitle1" sx={{ mb: 1, fontWeight: 'bold', color: '#091A48' }}>
                              Generated Content:
                            </Typography>
                            <TextField
                              fullWidth
                              multiline
                              rows={8}
                              value={postContent}
                              onChange={(e) => setPostContent(e.target.value)}
                              variant="outlined"
                              placeholder="Generated content will appear here..."
                              sx={{
                                '& .MuiOutlinedInput-root': {
                                  borderRadius: 2,
                                  '&:hover fieldset': {
                                    borderColor: '#882AFF',
                                  },
                                  '&.Mui-focused fieldset': {
                                    borderColor: '#882AFF',
                                  }
                                }
                              }}
                            />
                            <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
                              <Button
                                variant="outlined"
                                size="small"
                                startIcon={<CopyIcon />}
                                onClick={() => handleCopyUrl(postContent)}
                                sx={{
                                  borderColor: '#882AFF',
                                  color: '#882AFF',
                                  '&:hover': {
                                    borderColor: '#091A48',
                                    bgcolor: 'rgba(136, 42, 255, 0.04)',
                                  }
                                }}
                              >
                                Copy Content
                              </Button>
                              <Button
                                variant="outlined"
                                size="small"
                                onClick={() => setPostContent('')}
                                sx={{
                                  borderColor: '#ccc',
                                  color: '#666',
                                  '&:hover': {
                                    borderColor: '#999',
                                    bgcolor: 'rgba(0, 0, 0, 0.04)',
                                  }
                                }}
                              >
                                Clear
                              </Button>
                            </Box>
                          </Box>
                        )}
                      </Box>
                    )}
                  </CardContent>
                </Card>

                {/* Action Buttons */}
                <Box sx={{ display: 'flex', gap: 2, mt: 4 }}>
                  <Button
                    variant="outlined"
                    size="large"
                    sx={{
                      py: 1.5,
                      px: 4,
                      borderColor: '#882AFF',
                      color: '#882AFF',
                      '&:hover': {
                        borderColor: '#091A48',
                        bgcolor: 'rgba(136, 42, 255, 0.04)',
                      }
                    }}
                  >
                    Cancel
                  </Button>
                  <Button
                    variant="contained"
                    size="large"
                    onClick={handleCreateLink}
                    disabled={loading}
                    startIcon={loading ? <CircularProgress size={20} /> : <AddIcon />}
                    sx={{
                      py: 1.5,
                      px: 4,
                      fontSize: '1.1rem',
                      fontWeight: 'bold',
                      background: 'linear-gradient(45deg, #882AFF 30%, #091A48 90%)',
                      '&:hover': {
                        background: 'linear-gradient(45deg, #7a26e6 30%, #082040 90%)',
                      }
                    }}
                  >
                    {loading ? 'Creating your link...' : 'Create your link'}
                  </Button>
                </Box>
              </Grid>

              {/* Right Column - Preview */}
              <Grid item xs={12} lg={4}>
                <Card sx={{ position: 'sticky', top: 20, boxShadow: 3 }}>
                  <CardContent>
                    <Typography variant="h6" sx={{ mb: 2, color: '#091A48', fontWeight: 'bold' }}>
                      Preview
                    </Typography>
                    
                    {/* Short URL Preview */}
                    <Box sx={{ mb: 3, p: 2, bgcolor: '#f8f9ff', borderRadius: 2 }}>
                      <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>
                        Short URL:
                      </Typography>
                      <Typography variant="body1" sx={{ fontWeight: 'bold', color: '#882AFF' }}>
                        {getShortUrlPreview()}
                      </Typography>
                    </Box>

                    {/* UTM Tags Preview */}
                    {enableUTM && (
                      <Box sx={{ mb: 3, p: 2, bgcolor: '#f8fff8', borderRadius: 2 }}>
                        <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 2 }}>
                          UTM Tags:
                        </Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          {utmSource && (
                            <Typography variant="body2" sx={{ color: '#091A48', fontSize: '0.85rem' }}>
                              <strong>Source:</strong> {utmSource}
                            </Typography>
                          )}
                          {utmMedium && (
                            <Typography variant="body2" sx={{ color: '#091A48', fontSize: '0.85rem' }}>
                              <strong>Medium:</strong> {utmMedium}
                            </Typography>
                          )}
                          {utmCampaign && (
                            <Typography variant="body2" sx={{ color: '#091A48', fontSize: '0.85rem' }}>
                              <strong>Campaign:</strong> {utmCampaign}
                            </Typography>
                          )}
                          {utmTerm && (
                            <Typography variant="body2" sx={{ color: '#091A48', fontSize: '0.85rem' }}>
                              <strong>Term:</strong> {utmTerm}
                            </Typography>
                          )}
                          {utmContent && (
                            <Typography variant="body2" sx={{ color: '#091A48', fontSize: '0.85rem' }}>
                              <strong>Content:</strong> {utmContent}
                            </Typography>
                          )}
                          
                          {(utmSource || utmMedium || utmCampaign || utmTerm || utmContent) && (
                            <Box sx={{ 
                              mt: 2, 
                              p: 2, 
                              bgcolor: '#fff', 
                              borderRadius: 1, 
                              border: '1px solid #e0e0e0',
                              maxWidth: '100%',
                              overflow: 'hidden'
                            }}>
                              <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
                                Final URL with UTM:
                              </Typography>
                              <Box sx={{
                                maxHeight: '120px',
                                overflowY: 'auto',
                                overflowX: 'hidden',
                                '&::-webkit-scrollbar': {
                                  width: '4px',
                                },
                                '&::-webkit-scrollbar-track': {
                                  background: '#f1f1f1',
                                  borderRadius: '2px',
                                },
                                '&::-webkit-scrollbar-thumb': {
                                  background: '#c1c1c1',
                                  borderRadius: '2px',
                                },
                                '&::-webkit-scrollbar-thumb:hover': {
                                  background: '#a8a8a8',
                                }
                              }}>
                                <Typography 
                                  variant="body2" 
                                  sx={{ 
                                    wordBreak: 'break-all',
                                    overflowWrap: 'break-word',
                                    color: '#091A48',
                                    fontSize: '0.75rem',
                                    lineHeight: 1.4,
                                    whiteSpace: 'pre-wrap',
                                    display: 'block',
                                    width: '100%'
                                  }}
                                >
                                  {generatePreviewUrl()}
                                </Typography>
                              </Box>
                            </Box>
                          )}
                        </Box>
                      </Box>
                    )}

                    {/* QR Code Preview */}
                    {enableQR && (
                      <Box sx={{ mb: 3, p: 2, bgcolor: '#fff', borderRadius: 2, border: '1px solid #e0e0e0', textAlign: 'center' }}>
                        <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 2 }}>
                          QR Code Preview:
                        </Typography>
                        <img
                          src={generateQRCode()}
                          alt="QR Code Preview"
                          style={{ width: 120, height: 120 }}
                        />
                      </Box>
                    )}

                    {/* Features Summary */}
                    <Box sx={{ mt: 3 }}>
                      <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 2 }}>
                        Enabled Features:
                      </Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                        <Chip 
                          label="Short Link" 
                          size="small" 
                          sx={{ bgcolor: '#e3f2fd', color: '#1976d2' }}
                        />
                        {enableQR && (
                          <Chip 
                            label="QR Code" 
                            size="small" 
                            sx={{ bgcolor: '#f3e5f5', color: '#882AFF' }}
                          />
                        )}
                        {enableUTM && (
                          <Chip 
                            label="UTM Parameters" 
                            size="small" 
                            sx={{ bgcolor: '#e8f5e8', color: '#4caf50' }}
                          />
                        )}
                      </Box>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>

            {/* Generated URL Display */}
            {generatedUrl && (
              <Box sx={{ mt: 4, p: 4, bgcolor: '#f0f7ff', borderRadius: 3, border: '2px solid #e3f2fd' }}>
                <Typography variant="h5" sx={{ mb: 3, color: '#882AFF', fontWeight: 'bold' }}>
                  ✅ Link Created Successfully!
                </Typography>
                
                <Grid container spacing={3}>
                  <Grid item xs={12} md={8}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                      <TextField
                        value={generatedUrl.short_url}
                        variant="outlined"
                        size="small"
                        sx={{ flex: '1 1 auto' }}
                        InputProps={{
                          readOnly: true,
                          style: { fontWeight: 'bold', color: '#882AFF' }
                        }}
                      />
                      <Button
                        variant="contained"
                        startIcon={<CopyIcon />}
                        onClick={() => handleCopyUrl(generatedUrl.short_url)}
                        sx={{ 
                          bgcolor: '#882AFF',
                          '&:hover': { bgcolor: '#7a26e6' }
                        }}
                      >
                        Copy
                      </Button>
                      <Button
                        variant="outlined"
                        startIcon={<LaunchIcon />}
                        onClick={() => window.open(generatedUrl.short_url, '_blank')}
                        sx={{ 
                          borderColor: '#882AFF',
                          color: '#882AFF'
                        }}
                      >
                        Open
                      </Button>
                    </Box>
                    
                    <Box sx={{ mb: 2 }}>
                      <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                        <strong>Original URL:</strong>
                      </Typography>
                      <Box sx={{
                        p: 2,
                        bgcolor: '#f9f9f9',
                        borderRadius: 1,
                        border: '1px solid #e0e0e0',
                        maxHeight: '100px',
                        overflowY: 'auto',
                        overflowX: 'hidden',
                        '&::-webkit-scrollbar': {
                          width: '4px',
                        },
                        '&::-webkit-scrollbar-track': {
                          background: '#f1f1f1',
                          borderRadius: '2px',
                        },
                        '&::-webkit-scrollbar-thumb': {
                          background: '#c1c1c1',
                          borderRadius: '2px',
                        },
                        '&::-webkit-scrollbar-thumb:hover': {
                          background: '#a8a8a8',
                        }
                      }}>
                        <Typography 
                          variant="body2" 
                          sx={{ 
                            wordBreak: 'break-all',
                            overflowWrap: 'break-word',
                            fontSize: '0.85rem',
                            lineHeight: 1.4,
                            color: '#333'
                          }}
                        >
                          {generatedUrl.long_url}
                        </Typography>
                      </Box>
                    </Box>
                  </Grid>
                  
                  {generatedUrl.qr_code && (
                    <Grid item xs={12} md={4}>
                      <Box sx={{ textAlign: 'center' }}>
                        <Typography variant="subtitle2" sx={{ mb: 1 }}>
                          QR Code
                        </Typography>
                        <img
                          src={generatedUrl.qr_code}
                          alt="Generated QR Code"
                          style={{ width: 100, height: 100 }}
                        />
                      </Box>
                    </Grid>
                  )}
                </Grid>
              </Box>
            )}
          </CardContent>
        </Card>

        {/* Snackbar for notifications */}
        <Snackbar
          open={snackbar.open}
          autoHideDuration={4000}
          onClose={handleCloseSnackbar}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        >
          <Alert onClose={handleCloseSnackbar} severity={snackbar.severity} sx={{ width: '100%' }}>
            {snackbar.message}
          </Alert>
        </Snackbar>
      </Container>
    </Box>
  );
};

export default LinkAdvancedPage;